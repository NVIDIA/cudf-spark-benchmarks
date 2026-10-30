
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type
),
high_spenders AS (
    SELECT 
        *
    FROM 
        customer_data
    WHERE 
        total_spent > 500
),
ranked_customers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_spent DESC) AS rank
    FROM 
        high_spenders
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    full_address,
    total_orders,
    total_spent
FROM 
    ranked_customers
WHERE 
    rank <= 10
ORDER BY 
    ca_state, total_spent DESC;
