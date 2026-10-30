
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(ss.ss_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS online_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS in_store_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
average_sales AS (
    SELECT 
        AVG(total_spent) AS avg_spent,
        COUNT(*) AS customer_count
    FROM customer_sales
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_spent,
    cs.online_orders,
    cs.in_store_orders,
    (cs.total_spent - av.avg_spent) AS spent_difference,
    CASE 
        WHEN cs.total_spent > av.avg_spent THEN 'Above Average'
        WHEN cs.total_spent < av.avg_spent THEN 'Below Average'
        ELSE 'Average'
    END AS spending_frequency
FROM customer_sales cs
CROSS JOIN average_sales av
WHERE cs.total_spent IS NOT NULL
ORDER BY cs.total_spent DESC
LIMIT 10;
