
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 30
    GROUP BY 
        ws_item_sk
),
item_details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price
    FROM 
        item
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.i_current_price,
    sd.total_quantity,
    sd.total_sales,
    sd.total_orders
FROM 
    sales_data sd
JOIN 
    item_details id ON sd.ws_item_sk = id.i_item_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
