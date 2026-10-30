
SELECT 
    ca_city, 
    COUNT(*) AS customer_count 
FROM 
    customer_address 
GROUP BY 
    ca_city 
ORDER BY 
    customer_count DESC 
LIMIT 10;
