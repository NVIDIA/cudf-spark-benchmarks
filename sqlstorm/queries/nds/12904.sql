
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        ss.total_quantity,
        ss.total_sales
    FROM 
        item AS i
    JOIN 
        sales_summary AS ss ON i.i_item_sk = ss.ws_item_sk
)
SELECT 
    id.i_item_desc,
    id.total_quantity,
    id.total_sales,
    (id.total_sales / NULLIF(id.total_quantity, 0)) AS avg_price
FROM 
    item_details AS id
ORDER BY 
    id.total_sales DESC
LIMIT 10;
