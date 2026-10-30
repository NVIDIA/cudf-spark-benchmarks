
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COUNT(ss.ss_ticket_number) AS total_sales
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
