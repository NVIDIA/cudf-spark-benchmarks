
WITH  sales_summary AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 12 LIMIT 1)
        AND 
        (SELECT d_date_sk FROM date_dim WHERE d_year = 2024 AND d_moy = 1 LIMIT 1)
    GROUP BY 
        ws_order_number, ws_item_sk
    UNION ALL
    SELECT 
        cs_order_number,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_paid) DESC) AS rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 12 LIMIT 1)
        AND 
        (SELECT d_date_sk FROM date_dim WHERE d_year = 2024 AND d_moy = 1 LIMIT 1)
    GROUP BY 
        cs_order_number, cs_item_sk
),
top_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        SUM(ss.total_quantity) AS total_quantity,
        SUM(ss.total_sales) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.total_sales) DESC) AS rank
    FROM 
        sales_summary ss
    JOIN 
        item ON ss.ws_item_sk = item.i_item_sk 
    GROUP BY 
        item.i_item_id, item.i_item_desc
)
SELECT 
    items.i_item_id,
    items.i_item_desc,
    items.total_quantity,
    items.total_sales,
    CASE 
        WHEN items.total_sales IS NULL THEN 'No sales'
        WHEN items.total_sales > 1000 THEN 'High seller'
        WHEN items.total_sales BETWEEN 500 AND 1000 THEN 'Moderate seller'
        ELSE 'Low seller' 
    END AS sales_category
FROM 
    top_sales items
WHERE 
    items.rank <= 10
ORDER BY 
    items.total_sales DESC;
