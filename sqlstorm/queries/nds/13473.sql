
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_sk) AS customer_count, 
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ca_city
HAVING 
    AVG(cd_purchase_estimate) > 500
ORDER BY 
    customer_count DESC;
