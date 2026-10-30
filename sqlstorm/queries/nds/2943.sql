
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        cs.avg_order_value,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        customer_sales cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM customer_sales)
),
customer_demographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
customer_summary AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_orders,
        hvc.total_spent,
        hvc.avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        high_value_customers hvc
    JOIN 
        customer_demographics cd ON hvc.c_customer_sk = cd.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders,
    cs.total_spent,
    cs.avg_order_value,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.cd_purchase_estimate,
    COALESCE(NULLIF(cs.cd_marital_status, 'S'), 'Unknown') AS marital_status_display,
    CASE 
        WHEN cs.total_orders IS NULL THEN 'No Orders'
        WHEN cs.total_orders > 5 THEN 'Loyal Customer'
        ELSE 'New Customer'
    END AS customer_type
FROM 
    customer_summary cs
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM high_value_customers)
ORDER BY 
    cs.total_spent DESC 
LIMIT 10;
