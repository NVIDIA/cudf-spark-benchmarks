
WITH sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales 
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    COALESCE(ss.total_quantity, 0) AS total_quantity, 
    COALESCE(ss.total_sales, 0) AS total_sales 
FROM 
    item i 
LEFT JOIN 
    sales_summary ss ON i.i_item_sk = ss.ws_item_sk 
ORDER BY 
    total_sales DESC 
LIMIT 100;
