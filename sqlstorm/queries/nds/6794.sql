
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT 
        CASE 
            WHEN total_web_sales IS NULL THEN 0 
            ELSE total_web_sales 
        END AS web_sales,
        CASE 
            WHEN total_catalog_sales IS NULL THEN 0 
            ELSE total_catalog_sales 
        END AS catalog_sales,
        CASE 
            WHEN total_store_sales IS NULL THEN 0 
            ELSE total_store_sales 
        END AS store_sales,
        (COALESCE(total_web_sales, 0) + COALESCE(total_catalog_sales, 0) + COALESCE(total_store_sales, 0)) AS total_sales
    FROM CustomerSales
)
SELECT 
    web_sales,
    catalog_sales,
    store_sales,
    total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM SalesSummary
WHERE total_sales > 1000
ORDER BY sales_rank
LIMIT 10;
