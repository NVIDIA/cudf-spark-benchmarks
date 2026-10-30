
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_profit) AS average_profit_per_order,
        SUM(ws.ws_quantity) AS total_items_purchased
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY c.c_customer_id
),
TopCustomers AS (
    SELECT
        c.c_customer_id,
        cs.total_orders,
        cs.total_spent,
        cs.average_profit_per_order,
        cs.total_items_purchased,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT
    tc.c_customer_id AS customer_id,
    tc.total_orders,
    tc.total_spent,
    tc.average_profit_per_order,
    tc.total_items_purchased
FROM TopCustomers tc
WHERE tc.spending_rank <= 10
ORDER BY tc.total_spent DESC;
