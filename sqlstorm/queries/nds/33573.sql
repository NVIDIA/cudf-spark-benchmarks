
WITH  sales_data AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
),
top_selling_items AS (
    SELECT 
        sd.ws_item_sk, 
        sd.total_quantity, 
        sd.total_net_profit 
    FROM 
        sales_data sd 
    WHERE 
        sd.rank <= 5
),
return_summary AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax
    FROM
        store_returns
    GROUP BY 
        sr_item_sk
),
item_performance AS (
    SELECT 
        i.i_item_id,
        COALESCE(ts.total_quantity, 0) AS total_sold,
        COALESCE(ts.total_net_profit, 0) AS total_net_profit,
        COALESCE(rs.total_return_quantity, 0) AS total_returned_quantity,
        COALESCE(rs.total_return_amt_inc_tax, 0) AS total_returned_amount
    FROM 
        item i
    LEFT JOIN 
        top_selling_items ts ON i.i_item_sk = ts.ws_item_sk
    LEFT JOIN 
        return_summary rs ON i.i_item_sk = rs.sr_item_sk
)
SELECT 
    ip.i_item_id,
    ip.total_sold,
    ROUND(ip.total_net_profit - ip.total_returned_amount, 2) AS net_profit_after_returns,
    CASE 
        WHEN ip.total_sold > 0 THEN ROUND((ip.total_returned_quantity / ip.total_sold) * 100, 2)
        ELSE NULL
    END AS return_rate_percentage
FROM 
    item_performance ip
WHERE 
    ip.total_sold > 0
ORDER BY 
    net_profit_after_returns DESC;
