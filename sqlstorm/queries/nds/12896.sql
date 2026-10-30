
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS num_customers,
    SUM(sr_return_quantity) AS total_returned
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY 
    ca_state
ORDER BY 
    num_customers DESC
LIMIT 10;
