
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451546
),
returns_data AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
item_detail AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(ri.total_returns, 0) AS total_returns,
        SUM(sd.ws_quantity) AS total_sold,
        SUM(sd.ws_net_profit) AS total_profit
    FROM 
        item i
    LEFT JOIN 
        sales_data sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        returns_data ri ON i.i_item_sk = ri.cr_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, ri.total_returns
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.total_sold,
    id.total_profit,
    id.total_returns,
    CASE 
        WHEN id.total_returns > 0 THEN ROUND((id.total_returns * 100.0 / NULLIF(id.total_sold, 0)), 2)
        ELSE 0 
    END AS return_percentage
FROM 
    item_detail id
WHERE 
    id.total_profit > 0
    AND id.total_returns IS NOT NULL 
ORDER BY 
    return_percentage DESC
LIMIT 10;
