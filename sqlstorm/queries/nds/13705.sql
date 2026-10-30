
SELECT 
    c.c_customer_id, 
    ca.ca_city, 
    SUM(ss.ss_net_profit) AS total_net_profit
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'NY' AND
    ss.ss_sold_date_sk BETWEEN 2451545 AND 2451913
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_net_profit DESC
LIMIT 100;
