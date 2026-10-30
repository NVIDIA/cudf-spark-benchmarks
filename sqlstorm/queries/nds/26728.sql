
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_id) AS total_customers,
    AVG(cd_purchase_estimate) AS average_purchase_estimate,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers,
    CONCAT('City: ', ca_city, ' | Customers: ', COUNT(DISTINCT c_customer_id), ' | Avg Purchase: $', ROUND(AVG(cd_purchase_estimate), 2)) AS city_summary
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk 
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_city IS NOT NULL 
GROUP BY 
    ca_city
HAVING 
    COUNT(DISTINCT c_customer_id) > 10
ORDER BY 
    total_customers DESC;
