
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    SUM(ss.ss_net_profit) AS total_net_profit 
FROM 
    customer AS c 
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk 
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state 
ORDER BY 
    total_net_profit DESC 
LIMIT 10;
