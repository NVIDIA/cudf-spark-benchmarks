
WITH  purchases AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS order_rank
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
frequent_customers AS (
    SELECT 
        p.c_customer_sk,
        p.total_orders,
        p.total_spent
    FROM 
        purchases p 
    WHERE 
        p.total_orders > 1
),
ranked_customers AS (
    SELECT 
        f.c_customer_sk,
        f.total_orders,
        f.total_spent,
        RANK() OVER (ORDER BY f.total_spent DESC) AS customer_rank
    FROM 
        frequent_customers f
    WHERE 
        f.total_spent > (
            SELECT AVG(total_spent) 
            FROM frequent_customers
        )
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    r.customer_rank,
    COALESCE(r.total_orders, 0) AS orders_count,
    COALESCE(r.total_spent, 0.00) AS total_expenditure,
    CASE 
        WHEN r.total_orders IS NULL THEN 'No Purchases'
        WHEN r.total_orders > 5 THEN 'High Value'
        WHEN r.total_orders BETWEEN 3 AND 5 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM 
    customer c
LEFT JOIN 
    ranked_customers r ON c.c_customer_sk = r.c_customer_sk
ORDER BY 
    r.customer_rank;
