
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, 
        cd.cd_education_status, ca.ca_city, ca.ca_state
),
gender_stats AS (
    SELECT
        cd_gender,
        COUNT(*) AS gender_count,
        AVG(total_spent) AS avg_spent,
        SUM(total_orders) AS total_orders_per_gender
    FROM 
        customer_summary
    GROUP BY 
        cd_gender
),
state_summary AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers,
        SUM(CASE WHEN ws.ws_order_number IS NOT NULL THEN 1 ELSE 0 END) AS total_orders,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    g.cd_gender,
    g.gender_count,
    g.avg_spent,
    g.total_orders_per_gender,
    s.ca_state,
    s.unique_customers,
    s.total_orders,
    s.total_revenue
FROM 
    gender_stats g
CROSS JOIN 
    state_summary s
ORDER BY 
    g.cd_gender, s.ca_state;
