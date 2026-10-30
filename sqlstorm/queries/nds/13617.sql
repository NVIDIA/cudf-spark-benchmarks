
SELECT 
    ca_country, 
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(ss_net_profit) AS total_net_profit
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
GROUP BY 
    ca_country
ORDER BY 
    total_net_profit DESC
LIMIT 10;
