
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    sd.total_quantity,
    sd.total_sales,
    sd.total_profit
FROM 
    item AS i
JOIN 
    sales_data AS sd ON i.i_item_sk = sd.ws_item_sk
ORDER BY 
    sd.total_profit DESC
LIMIT 10;
