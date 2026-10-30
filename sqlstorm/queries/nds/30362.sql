WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS item_rank
    FROM 
        sales_summary ss
    WHERE 
        ss.total_quantity > 100
)
SELECT 
    ti.ws_item_sk,
    i.i_item_desc,
    i.i_current_price,
    ti.total_quantity,
    ti.total_sales,
    CASE 
        WHEN ti.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sale_status,
    COALESCE(i.i_brand, 'Unknown') AS item_brand
FROM 
    top_items ti
LEFT JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE 
    ti.item_rank <= 10
ORDER BY 
    ti.total_sales DESC;