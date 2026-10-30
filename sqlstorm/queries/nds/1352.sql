
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, total_sales
    FROM CustomerSales
    WHERE sales_rank <= 10
),
SalesSummary AS (
    SELECT 
        SUM(total_sales) AS total_sales_sum,
        AVG(total_sales) AS average_sales,
        COUNT(*) AS customer_count
    FROM TopCustomers
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    s.total_sales_sum,
    s.average_sales,
    s.customer_count,
    CASE 
        WHEN tc.total_sales > s.average_sales THEN 'Above Average'
        WHEN tc.total_sales < s.average_sales THEN 'Below Average'
        ELSE 'Exactly Average'
    END AS sales_category
FROM TopCustomers tc
CROSS JOIN SalesSummary s
ORDER BY tc.total_sales DESC;
