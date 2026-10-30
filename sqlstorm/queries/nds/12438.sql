
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_id) AS total_customers, 
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count, 
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count 
FROM 
    customer_address ca 
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk 
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
GROUP BY 
    ca_city 
ORDER BY 
    total_customers DESC 
LIMIT 10;
