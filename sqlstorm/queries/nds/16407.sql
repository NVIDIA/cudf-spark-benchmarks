
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    a.ca_city, 
    SUM(ss.ss_net_paid) AS total_spent
FROM 
    customer c
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    a.ca_city
ORDER BY 
    total_spent DESC
LIMIT 10;
