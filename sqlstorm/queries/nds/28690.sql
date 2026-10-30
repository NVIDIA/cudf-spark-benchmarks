
SELECT 
    c.c_customer_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    SUBSTRING(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1) AS email_user,
    UPPER(ca.ca_country) AS country_uppercase,
    REPLACE(ca.ca_street_name, ' ', '-') AS street_name_hyphenated
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    c.c_email_address, 
    ca.ca_country, 
    ca.ca_street_name
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5 AND SUM(ws.ws_net_paid) > 500
ORDER BY 
    total_spent DESC;
