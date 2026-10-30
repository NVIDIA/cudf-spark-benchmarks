
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
return_data AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
final_data AS (
    SELECT 
        sd.ws_item_sk,
        sd.ws_quantity,
        sd.ws_ext_sales_price,
        COALESCE(rd.total_returned, 0) AS total_returned,
        COALESCE(rd.total_returned_amount, 0) AS total_returned_amount,
        sd.ws_net_profit - COALESCE(rd.total_returned_amount, 0) AS net_profit_after_returns
    FROM 
        sales_data sd
    LEFT JOIN 
        return_data rd ON sd.ws_item_sk = rd.sr_item_sk
    WHERE 
        sd.rank <= 5
)
SELECT 
    f.ws_item_sk,
    f.ws_quantity,
    f.ws_ext_sales_price,
    f.total_returned,
    f.total_returned_amount,
    f.net_profit_after_returns,
    CASE 
        WHEN f.net_profit_after_returns > 0 THEN 'Profitable'
        ELSE 'Unprofitable'
    END AS profitability_status
FROM 
    final_data f
ORDER BY 
    f.net_profit_after_returns DESC;
