WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer c
    INNER JOIN 
        customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.total_orders > 0
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_spent,
    CASE 
        WHEN tc.rank <= 10 THEN 'Top 10 Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    top_customers tc
WHERE 
    tc.total_spent IS NOT NULL 
ORDER BY 
    tc.total_spent DESC;