
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_sales_price
FROM 
    sales_summary ss
JOIN 
    item i ON ss.ws_item_sk = i.i_item_sk
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
