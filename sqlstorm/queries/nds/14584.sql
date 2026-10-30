
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_id) AS number_of_customers, 
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count, 
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count 
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk 
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk 
GROUP BY 
    ca_state 
ORDER BY 
    number_of_customers DESC 
LIMIT 10;
