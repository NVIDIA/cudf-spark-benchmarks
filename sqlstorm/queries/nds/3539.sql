
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_quantity,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent > 1000 THEN 'High Value'
            WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer_stats cs
    WHERE 
        cs.order_count > 5
),
shipping_modes AS (
    SELECT 
        ws.ws_ship_mode_sk,
        sm.sm_type,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.ws_ship_mode_sk, sm.sm_type
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    hvc.customer_value,
    sm.sm_type AS shipping_method,
    COALESCE(sm.total_revenue, 0) AS revenue_from_shipping,
    CASE 
        WHEN hvc.total_spent IS NULL THEN 'No Purchases'
        ELSE 'Purchases Made'
    END AS purchase_status
FROM 
    high_value_customers hvc
LEFT JOIN 
    shipping_modes sm ON hvc.c_customer_sk = sm.ws_ship_mode_sk
WHERE 
    hvc.customer_value = 'High Value'
ORDER BY 
    hvc.total_spent DESC
LIMIT 100;
