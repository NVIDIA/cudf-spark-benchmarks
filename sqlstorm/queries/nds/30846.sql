
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
ranked_sales AS (
    SELECT 
        ws_item_sk,
        total_quantity_sold,
        total_sales,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
    WHERE 
        sales_rank <= 10
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(r.total_quantity_sold, 0) AS online_sales_quantity,
    COALESCE(s.total_quantity_sold, 0) AS catalog_sales_quantity,
    COALESCE(r.total_sales, 0) AS online_sales_total,
    COALESCE(s.total_sales, 0) AS catalog_sales_total,
    CASE 
        WHEN COALESCE(r.total_sales, 0) > COALESCE(s.total_sales, 0) THEN 'Web'
        WHEN COALESCE(r.total_sales, 0) < COALESCE(s.total_sales, 0) THEN 'Catalog'
        ELSE 'Equal'
    END AS dominant_sales_channel
FROM 
    item i
LEFT JOIN (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
) r ON i.i_item_sk = r.ws_item_sk
LEFT JOIN (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_sales_price) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
) s ON i.i_item_sk = s.cs_item_sk
WHERE 
    COALESCE(r.total_sales, 0) + COALESCE(s.total_sales, 0) > 0
ORDER BY 
    online_sales_total DESC, 
    catalog_sales_total DESC;
