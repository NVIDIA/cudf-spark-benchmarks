
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_sk) AS customer_count, 
    AVG(cd_purchase_estimate) AS avg_purchase_estimate 
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk 
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk 
GROUP BY 
    ca_city 
ORDER BY 
    customer_count DESC 
LIMIT 10;
