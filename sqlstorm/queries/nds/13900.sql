
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_sk) AS customer_count, 
    SUM(sr_return_quantity) AS total_returned_quantity
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY 
    ca_city
HAVING 
    COUNT(DISTINCT c_customer_sk) > 10
ORDER BY 
    total_returned_quantity DESC
LIMIT 100;
