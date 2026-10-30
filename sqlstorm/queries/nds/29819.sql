
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS email_domain,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip, 
        ca.ca_country, 
        c.c_email_address
),
top_customers AS (
    SELECT 
        full_name, 
        cd_gender, 
        cd_marital_status, 
        ca_city, 
        ca_state, 
        ca_zip, 
        ca_country, 
        email_domain, 
        total_orders,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_orders DESC) AS rn
    FROM 
        customer_details
)
SELECT 
    full_name, 
    cd_gender, 
    cd_marital_status,
    ca_city, 
    ca_state, 
    ca_zip, 
    ca_country, 
    email_domain, 
    total_orders
FROM 
    top_customers
WHERE 
    rn <= 5
ORDER BY 
    cd_gender, 
    total_orders DESC;
