
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    sd.total_quantity,
    sd.total_sales,
    sd.total_profit
FROM 
    sales_data sd
JOIN 
    item i ON sd.ws_item_sk = i.i_item_sk
ORDER BY 
    sd.total_profit DESC
LIMIT 10;
