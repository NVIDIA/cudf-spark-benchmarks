
SELECT 
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type) AS full_address,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid_inc_tax) AS total_spent
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_street_number, 
    ca.ca_street_name, 
    ca.ca_street_type, 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 10 
ORDER BY 
    total_spent DESC;
