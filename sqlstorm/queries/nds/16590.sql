
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_id) AS customer_count 
FROM 
    customer_address CA 
JOIN 
    customer C 
ON 
    CA.ca_address_sk = C.c_current_addr_sk 
GROUP BY 
    ca_city 
ORDER BY 
    customer_count DESC 
LIMIT 10;
