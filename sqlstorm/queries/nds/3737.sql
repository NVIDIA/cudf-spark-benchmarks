
WITH customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cp.total_orders,
        cp.total_spent,
        CASE 
            WHEN cp.total_spent > 1000 THEN 'High'
            WHEN cp.total_spent BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS customer_value
    FROM 
        customer c
    JOIN 
        customer_purchases cp ON c.c_customer_sk = cp.c_customer_sk
),
recent_orders AS (
    SELECT 
        ws.ws_ship_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_ship_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS order_rank
    FROM 
        web_sales ws
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_orders,
    hvc.total_spent,
    hvc.customer_value,
    COALESCE(recent_orders.order_rank, 0) AS recent_order_rank
FROM 
    high_value_customers hvc
LEFT JOIN 
    recent_orders ON hvc.c_customer_sk = recent_orders.ws_ship_customer_sk 
WHERE 
    hvc.total_spent > 500
ORDER BY 
    hvc.total_spent DESC, 
    hvc.c_last_name ASC
LIMIT 10;
