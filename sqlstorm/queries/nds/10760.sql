
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    sd.total_quantity,
    sd.total_sales,
    sd.order_count
FROM 
    item i
JOIN 
    sales_data sd ON i.i_item_sk = sd.ws_item_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
