
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
TopCustomers AS (
    SELECT
        c_customer_id,
        total_spent,
        web_orders,
        catalog_orders,
        store_orders,
        RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM CustomerSales
)
SELECT
    tc.c_customer_id,
    tc.total_spent,
    tc.web_orders,
    tc.catalog_orders,
    tc.store_orders,
    CASE
        WHEN tc.customer_rank <= 10 THEN 'Top 10 Customers'
        WHEN tc.customer_rank <= 50 THEN 'Top 50 Customers'
        ELSE 'Other Customers'
    END AS customer_segment
FROM TopCustomers tc
WHERE tc.total_spent > 1000
ORDER BY tc.total_spent DESC;
