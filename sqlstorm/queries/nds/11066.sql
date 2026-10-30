
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
item_data AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        item i
    LEFT JOIN 
        sales_data sd ON i.i_item_sk = sd.ws_item_sk
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.total_sales,
    id.total_orders
FROM 
    item_data id
ORDER BY 
    id.total_sales DESC
LIMIT 10;
