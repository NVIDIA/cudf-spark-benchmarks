
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_sales,
        store_sales_count,
        web_sales_count,
        catalog_sales_count
    FROM CustomerSales
    WHERE sales_rank <= 10
),
AvgSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales,
        AVG(store_sales_count) AS avg_store_sales,
        AVG(web_sales_count) AS avg_web_sales,
        AVG(catalog_sales_count) AS avg_catalog_sales
    FROM TopCustomers
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.store_sales_count,
    tc.web_sales_count,
    tc.catalog_sales_count,
    CASE 
        WHEN tc.total_sales > (SELECT avg_sales FROM AvgSales) THEN 'Above Average'
        WHEN tc.total_sales < (SELECT avg_sales FROM AvgSales) THEN 'Below Average'
        ELSE 'Average'
    END AS sales_performance
FROM TopCustomers tc
ORDER BY tc.total_sales DESC;
