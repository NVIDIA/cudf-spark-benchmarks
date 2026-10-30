
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_id) AS unique_customers
FROM 
    customer_address 
JOIN 
    customer ON customer.c_current_addr_sk = ca_address_sk
GROUP BY 
    ca_state
ORDER BY 
    unique_customers DESC
LIMIT 10;
