
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450032 AND 2450038
    GROUP BY 
        ws_item_sk
),
aggregated_returns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM 
        catalog_returns
    WHERE 
        cr_returned_date_sk IN (SELECT DISTINCT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cr_item_sk
),
item_sales_with_returns AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity - COALESCE(ar.total_return_quantity, 0) AS net_quantity,
        rs.total_sales,
        rs.rank
    FROM 
        ranked_sales rs
    LEFT JOIN 
        aggregated_returns ar ON rs.ws_item_sk = ar.cr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(iss.net_quantity, 0) AS adjusted_quantity,
    iss.total_sales,
    CASE 
        WHEN iss.total_sales IS NULL THEN 'No Sales'
        WHEN iss.total_sales > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS sales_category
FROM 
    item i
LEFT JOIN 
    item_sales_with_returns iss ON i.i_item_sk = iss.ws_item_sk
WHERE 
    i.i_current_price IS NOT NULL AND 
    (i.i_class_id IS NOT NULL OR i.i_brand_id IS NULL)
ORDER BY 
    adjusted_quantity DESC,
    i.i_item_desc
LIMIT 10;
