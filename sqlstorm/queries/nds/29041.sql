
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        REPLACE(ca_city, ' ', '_') AS sanitized_city,
        UPPER(ca_state) AS upper_state
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        da.full_address,
        da.sanitized_city,
        da.upper_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses da ON c.c_current_addr_sk = da.ca_address_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    AVG(ws.ws_ext_sales_price) AS avg_order_value
FROM 
    customer_info ci
LEFT JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ci.upper_state = 'NY'
GROUP BY 
    ci.full_name, ci.cd_gender, ci.cd_marital_status, ci.cd_education_status
HAVING 
    COUNT(ws.ws_order_number) > 1
ORDER BY 
    total_spent DESC;
