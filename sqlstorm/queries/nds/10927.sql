
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws_item_sk
)
SELECT 
    i_item_id,
    i_product_name,
    sales.total_quantity,
    sales.total_sales
FROM 
    item AS item
JOIN 
    SalesData AS sales ON item.i_item_sk = sales.ws_item_sk
ORDER BY 
    sales.total_sales DESC
LIMIT 10;
