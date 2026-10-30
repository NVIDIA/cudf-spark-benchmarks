
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    AVG(ws.ws_sales_price) AS avg_order_value,
    SUBSTRING(c.c_birth_country, 1, 3) AS country_prefix,
    REPLACE(UPPER(c.c_email_address), '@', '[AT]') AS obfuscated_email
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA' AND 
    cd.cd_marital_status = 'M'
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, 
    ca.ca_city, ca.ca_state, ca.ca_zip, 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status,
    c.c_birth_country, c.c_email_address
ORDER BY 
    total_spent DESC
LIMIT 100;
