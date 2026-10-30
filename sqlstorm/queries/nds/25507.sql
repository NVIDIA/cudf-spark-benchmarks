
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
top_customers AS (
    SELECT
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer_info ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.full_name, ci.ca_city, ci.ca_state
    ORDER BY 
        total_orders DESC
    LIMIT 10
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_orders,
    CASE
        WHEN total_orders > 50 THEN 'High Value'
        WHEN total_orders BETWEEN 20 AND 50 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    top_customers
WHERE 
    ca_state IN ('CA', 'NY', 'TX')
ORDER BY 
    full_name;
