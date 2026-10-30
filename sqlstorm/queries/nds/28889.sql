
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
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
high_value_customers AS (
    SELECT 
        cd.c_customer_sk,
        cd.full_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer_details cd
    JOIN 
        web_sales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.c_customer_sk, cd.full_name
    HAVING 
        SUM(ws.ws_sales_price) > 1000
),
top_cities AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
    ORDER BY 
        customer_count DESC 
    LIMIT 5
)
SELECT 
    hvc.full_name,
    hvc.total_orders,
    hvc.total_spent,
    tc.ca_city
FROM 
    high_value_customers hvc
JOIN 
    customer_details cd ON hvc.c_customer_sk = cd.c_customer_sk
JOIN 
    top_cities tc ON cd.ca_city = tc.ca_city
ORDER BY 
    hvc.total_spent DESC;
