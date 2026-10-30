
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_net_paid, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        RANK() OVER (ORDER BY cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales DESC) AS sales_rank
    FROM CustomerSales cs
),
HighValueCustomers AS (
    SELECT 
        sr.c_customer_sk,
        sr.c_first_name,
        sr.c_last_name,
        sr.total_web_sales,
        sr.total_catalog_sales,
        sr.total_store_sales
    FROM SalesRanked sr
    WHERE sr.sales_rank <= 10
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name || ' ' || hvc.c_last_name AS full_name,
    COALESCE(hvc.total_web_sales, 0) AS web_sales,
    COALESCE(hvc.total_catalog_sales, 0) AS catalog_sales,
    COALESCE(hvc.total_store_sales, 0) AS store_sales,
    (COALESCE(hvc.total_web_sales, 0) + COALESCE(hvc.total_catalog_sales, 0) + COALESCE(hvc.total_store_sales, 0)) AS total_sales,
    CASE 
        WHEN (COALESCE(hvc.total_web_sales, 0) + COALESCE(hvc.total_catalog_sales, 0) + COALESCE(hvc.total_store_sales, 0)) = 0 THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM HighValueCustomers hvc
ORDER BY total_sales DESC;
