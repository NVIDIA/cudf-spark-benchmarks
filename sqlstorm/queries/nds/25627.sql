
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    AVG(LENGTH(ca.ca_street_name)) AS avg_street_name_length,
    MAX(LENGTH(ca.ca_city)) AS max_city_name_length,
    MIN(LENGTH(ca.ca_zip)) AS min_zip_length
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 2000
    AND ca.ca_country = 'USA'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
ORDER BY 
    total_spent DESC
LIMIT 50;
