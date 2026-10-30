
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    sd.total_sales,
    sd.order_count
FROM 
    sales_data sd
JOIN 
    item i ON sd.ws_item_sk = i.i_item_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
