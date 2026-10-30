
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_sk) AS customer_count
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_marital_status = 'M' 
    AND cd.cd_gender = 'F'
GROUP BY 
    ca_city
ORDER BY 
    customer_count DESC
LIMIT 10;
