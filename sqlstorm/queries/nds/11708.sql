
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ss.total_quantity,
    ss.total_sales,
    ss.total_orders
FROM 
    item i
JOIN 
    sales_summary ss ON i.i_item_sk = ss.ws_item_sk
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
