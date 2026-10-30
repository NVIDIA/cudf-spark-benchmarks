
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(LENGTH(c.c_email_address)) AS avg_email_length,
    MAX(LENGTH(ca.ca_street_name)) AS max_street_length,
    MIN(LENGTH(ca.ca_city)) AS min_city_length
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA'
AND 
    c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state
HAVING 
    SUM(ws.ws_ext_sales_price) > 1000
ORDER BY 
    total_orders DESC, 
    total_sales DESC;
