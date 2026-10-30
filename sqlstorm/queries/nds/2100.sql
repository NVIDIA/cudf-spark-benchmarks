
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0) + COALESCE(ss.ss_net_paid_inc_tax, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS online_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
RankedCustomers AS (
    SELECT 
        c.c_customer_id AS customer_id, 
        cs.total_spent, 
        cs.online_orders, 
        cs.catalog_orders, 
        cs.store_orders,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    rc.customer_id,
    rc.total_spent,
    rc.online_orders,
    rc.catalog_orders,
    rc.store_orders,
    CASE 
        WHEN rc.total_spent > 1000 THEN 'VIP'
        WHEN rc.total_spent > 500 THEN 'Regular'
        ELSE 'New'
    END AS customer_tier,
    (SELECT COUNT(*) 
     FROM RankedCustomers 
     WHERE online_orders > rc.online_orders) AS better_online_order_count,
    (SELECT AVG(total_spent) 
     FROM RankedCustomers 
     WHERE rank <= 10
    ) AS avg_top_10_spent
FROM RankedCustomers rc
WHERE rc.rank <= 100
ORDER BY rc.total_spent DESC;
