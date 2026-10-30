
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name, 
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS address,
    ca.ca_city, 
    ca.ca_state, 
    ca.ca_zip, 
    cd.cd_gender, 
    cd.cd_marital_status,     
    COALESCE(CONCAT('Estimated Purchase: ', cd.cd_purchase_estimate), 'N/A') AS purchase_estimate,
    SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1) AS email_domain,
    COUNT(ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_net_profit) AS total_net_profit
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
    cd.cd_gender = 'F'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_street_number, ca.ca_street_name, 
    ca.ca_street_type, ca.ca_city, ca.ca_state, ca.ca_zip, cd.cd_gender, 
    cd.cd_marital_status, cd.cd_purchase_estimate, c.c_email_address
ORDER BY 
    total_net_profit DESC 
LIMIT 10;
