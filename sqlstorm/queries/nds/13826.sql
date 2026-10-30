
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ss.ss_net_profit) AS total_net_profit
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'CA'
    AND ss.ss_sold_date_sk BETWEEN 2453540 AND 2453547
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_net_profit DESC
LIMIT 100;
