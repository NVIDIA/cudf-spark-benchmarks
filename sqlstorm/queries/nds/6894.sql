
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id
),
SalesSummary AS (
    SELECT
        c_customer_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        (total_web_sales + total_catalog_sales + total_store_sales) AS total_sales,
        CASE
            WHEN (total_web_sales + total_catalog_sales + total_store_sales) > 100000 THEN 'High Value'
            WHEN (total_web_sales + total_catalog_sales + total_store_sales) BETWEEN 50000 AND 100000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM
        CustomerSales
)
SELECT 
    COUNT(*) AS count_high_value_customers,
    SUM(total_web_sales) AS total_web_sales_high_value,
    AVG(total_catalog_sales) AS avg_catalog_sales_high_value,
    MIN(total_store_sales) AS min_store_sales_high_value
FROM 
    SalesSummary
WHERE 
    customer_value_category = 'High Value'
UNION ALL
SELECT 
    COUNT(*) AS count_medium_value_customers,
    SUM(total_web_sales) AS total_web_sales_medium_value,
    AVG(total_catalog_sales) AS avg_catalog_sales_medium_value,
    MIN(total_store_sales) AS min_store_sales_medium_value
FROM 
    SalesSummary
WHERE 
    customer_value_category = 'Medium Value'
UNION ALL
SELECT 
    COUNT(*) AS count_low_value_customers,
    SUM(total_web_sales) AS total_web_sales_low_value,
    AVG(total_catalog_sales) AS avg_catalog_sales_low_value,
    MIN(total_store_sales) AS min_store_sales_low_value
FROM 
    SalesSummary
WHERE 
    customer_value_category = 'Low Value';
