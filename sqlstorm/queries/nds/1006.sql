
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_spent,
        SUM(COALESCE(cs.cs_net_paid, 0)) AS total_catalog_spent,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        total_web_spent + total_catalog_spent AS total_spent,
        ROW_NUMBER() OVER (ORDER BY total_web_spent + total_catalog_spent DESC) AS spending_rank
    FROM CustomerSales c
    WHERE (total_web_spent + total_catalog_spent) > 0
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS gender,
    ROUND((tc.total_spent * 1.1), 2) AS adjusted_spent
FROM TopCustomers tc
LEFT JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE tc.spending_rank <= 10
ORDER BY adjusted_spent DESC
