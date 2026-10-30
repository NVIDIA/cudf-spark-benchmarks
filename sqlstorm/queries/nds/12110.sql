
SELECT 
    c.c_customer_id, 
    ca.ca_city, 
    SUM(ss.ss_net_profit) AS total_net_profit 
FROM 
    customer AS c 
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN 
    store_sales AS ss ON ss.ss_customer_sk = c.c_customer_sk 
WHERE 
    ca.ca_state = 'CA' 
GROUP BY 
    c.c_customer_id, ca.ca_city 
ORDER BY 
    total_net_profit DESC 
LIMIT 100;
