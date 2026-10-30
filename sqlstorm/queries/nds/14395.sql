
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_sk) AS num_customers, 
    SUM(ss_net_profit) AS total_net_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca_state = 'CA'
GROUP BY 
    ca_city
ORDER BY 
    total_net_profit DESC
LIMIT 10;
