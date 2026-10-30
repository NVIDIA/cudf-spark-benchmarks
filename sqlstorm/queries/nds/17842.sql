
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_id) AS customer_count
FROM 
    customer 
JOIN 
    customer_address ON c_current_addr_sk = ca_address_sk
GROUP BY 
    ca_state
ORDER BY 
    customer_count DESC
LIMIT 10;
