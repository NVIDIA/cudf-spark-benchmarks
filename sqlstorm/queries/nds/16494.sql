
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS total_customers, 
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers 
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk 
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk 
GROUP BY 
    ca_state 
ORDER BY 
    total_customers DESC;
