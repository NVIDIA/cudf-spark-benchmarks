
WITH  sales_summary AS (
    SELECT 
        cs_sold_date_sk, 
        cs_item_sk, 
        SUM(cs_sales_price) AS total_sales,
        COUNT(*) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk DESC) AS rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
), item_details AS (
    SELECT 
        i_item_sk, 
        i_product_name, 
        i_brand, 
        i_category,
        COALESCE(
            (SELECT MIN(price) FROM (
                SELECT ws_sales_price AS price 
                FROM web_sales 
                WHERE ws_item_sk = i_item_sk
                UNION ALL
                SELECT cs_sales_price AS price 
                FROM catalog_sales 
                WHERE cs_item_sk = i_item_sk
            ) AS all_prices), 0) AS min_price
    FROM 
        item
), aggregated_sales AS (
    SELECT 
        id.i_item_sk,
        id.i_product_name, 
        id.i_brand, 
        id.i_category,
        ss.total_sales, 
        ss.total_transactions,
        CASE 
            WHEN ss.total_sales IS NULL THEN 'No Sales'
            ELSE 'Sales Recorded'
        END AS sales_status
    FROM 
        item_details id 
    LEFT JOIN 
        sales_summary ss ON id.i_item_sk = ss.cs_item_sk
)
SELECT 
    a.i_item_sk,
    a.i_product_name,
    a.i_brand,
    a.i_category,
    a.total_sales,
    a.total_transactions,
    a.sales_status,
    CASE 
        WHEN a.total_sales > 1000 THEN 'High Revenue'
        WHEN a.total_sales BETWEEN 500 AND 1000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    aggregated_sales a
WHERE 
    a.sales_status = 'Sales Recorded' 
    AND (SELECT COUNT(*) FROM customer_demographics cd WHERE cd.cd_purchase_estimate > 500) > 10
ORDER BY 
    a.total_sales DESC
LIMIT 50;

