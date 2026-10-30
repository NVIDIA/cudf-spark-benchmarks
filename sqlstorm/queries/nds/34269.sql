
WITH  sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk

    UNION ALL

    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity, 
        SUM(cs_ext_sales_price) AS total_sales
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY cs_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ss.total_sales, 0) AS total_sales,
    DENSE_RANK() OVER (ORDER BY COALESCE(ss.total_sales, 0) DESC) AS sales_rank,
    (SELECT COUNT(DISTINCT ws_bill_customer_sk) 
        FROM web_sales 
        WHERE ws_item_sk = i.i_item_sk) AS unique_customers

FROM item i
LEFT JOIN sales_summary ss ON ss.ws_item_sk = i.i_item_sk
WHERE i.i_current_price > 20.00
AND (
    SELECT COUNT(*)
    FROM store_sales ss
    WHERE ss.ss_item_sk = i.i_item_sk
    AND ss.ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
) > 0
ORDER BY sales_rank
LIMIT 100;
