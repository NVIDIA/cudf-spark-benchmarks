
WITH CustomerSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
           COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
           COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cs.total_web_sales,
           cs.total_catalog_sales,
           cs.total_store_sales,
           (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_sales,
           NTILE(4) OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales)) AS sales_quartile
    FROM CustomerSales cs
    JOIN customer c ON c.c_customer_sk = cs.c_customer_sk
    WHERE (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) > 1000
),
SalesRank AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           total_sales,
           sales_quartile,
           DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesSummary c
)
SELECT sr.c_customer_sk, sr.c_first_name, sr.c_last_name,
       sr.total_sales, sr.sales_quartile, sr.sales_rank,
       CASE 
           WHEN sr.sales_rank <= 10 THEN 'Top 10%'
           WHEN sr.sales_rank <= 30 THEN 'Top 30%'
           ELSE 'Others' 
       END AS sales_category
FROM SalesRank sr
WHERE sr.sales_quartile = 2
ORDER BY sr.total_sales DESC;
