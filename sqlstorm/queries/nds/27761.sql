
WITH customer_details AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, full_name, cd.cd_gender, cd.cd_marital_status, 
        cd.cd_education_status, ca.ca_city, ca.ca_state, ca.ca_country
),
high_value_customers AS (
    SELECT 
        *,
        CASE 
            WHEN total_spent > 1000 THEN 'High Value'
            WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM 
        customer_details
)
SELECT 
    customer_value_category,
    COUNT(*) AS customer_count,
    AVG(total_spent) AS avg_spending,
    MAX(total_orders) AS max_orders
FROM 
    high_value_customers
GROUP BY 
    customer_value_category
ORDER BY 
    customer_value_category DESC;
