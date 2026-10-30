
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    a.ca_city,
    a.ca_state,
    SUM(ss.ss_net_paid) AS total_spent
FROM 
    customer c
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state
HAVING 
    SUM(ss.ss_net_paid) > 1000
ORDER BY 
    total_spent DESC
LIMIT 10;
