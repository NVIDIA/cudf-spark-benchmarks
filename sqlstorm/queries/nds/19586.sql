
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COUNT(*) AS total_orders
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_orders DESC
LIMIT 10;
