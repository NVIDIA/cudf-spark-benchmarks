
WITH customer_orders AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT CASE WHEN ws_order_number IS NOT NULL THEN ws_order_number END) AS total_orders,
        COALESCE(SUM(ws_net_paid), 0) AS total_spent,
        c.c_birth_month,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(ws_net_paid), 0) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_birth_month
),

avg_spent AS (
    SELECT 
        AVG(total_spent) AS average_spent,
        SUM(CASE WHEN total_orders > 5 THEN total_spent ELSE 0 END) / NULLIF(SUM(CASE WHEN total_orders > 5 THEN 1 ELSE 0 END), 0) AS premium_customer_avg
    FROM 
        customer_orders
),

customer_status AS (
    SELECT 
        co.c_customer_sk,
        CASE 
            WHEN co.total_orders > 10 THEN 'VIP'
            WHEN co.total_orders BETWEEN 5 AND 10 THEN 'Regular'
            ELSE 'Occasional'
        END AS customer_type,
        co.total_spent,
        cs.average_spent,
        DENSE_RANK() OVER (ORDER BY co.total_spent DESC) AS spender_rank
    FROM 
        customer_orders co
    CROSS JOIN 
        avg_spent cs
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.customer_type,
    cs.total_spent,
    cs.spender_rank
FROM 
    customer c
JOIN 
    customer_status cs ON c.c_customer_sk = cs.c_customer_sk
WHERE 
    (cs.spender_rank <= 100 OR cs.total_spent > (SELECT average_spent FROM avg_spent) * 1.5)
    AND cs.total_spent IS NOT NULL
ORDER BY 
    cs.total_spent DESC
LIMIT 30 OFFSET 5;
