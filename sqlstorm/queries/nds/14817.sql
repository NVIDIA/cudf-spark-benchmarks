
WITH CustomerSales AS (
    SELECT c.c_customer_sk, SUM(ss.ss_sales_price) AS total_sales
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
TopCustomers AS (
    SELECT c.c_customer_sk, cs.total_sales
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    ORDER BY cs.total_sales DESC
    LIMIT 10
)
SELECT c.c_customer_id, c.c_first_name, c.c_last_name, tc.total_sales
FROM TopCustomers tc
JOIN customer c ON tc.c_customer_sk = c.c_customer_sk;
