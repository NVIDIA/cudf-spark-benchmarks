
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_net_paid, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRank AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY (total_web_sales + total_catalog_sales + total_store_sales) DESC) AS sales_rank
    FROM CustomerSales c
)
SELECT 
    sr.c_first_name,
    sr.c_last_name,
    COALESCE(sr.total_web_sales, 0) AS total_web_sales,
    COALESCE(sr.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(sr.total_store_sales, 0) AS total_store_sales,
    CASE 
        WHEN (total_web_sales + total_catalog_sales + total_store_sales) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS status,
    SUBSTRING(CONCAT(sr.c_first_name, ' ', sr.c_last_name), 1, 20) AS full_name,
    sr.sales_rank
FROM SalesRank sr
WHERE sr.sales_rank <= 10
ORDER BY sr.sales_rank;
