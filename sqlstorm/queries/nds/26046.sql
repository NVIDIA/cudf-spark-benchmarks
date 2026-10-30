
SELECT 
    ca.ca_city AS city,
    ca.ca_state AS state,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_city IS NOT NULL AND
    ca.ca_state IN ('CA', 'NY', 'TX') AND 
    LENGTH(ca.ca_zip) = 5
GROUP BY 
    ca.ca_city, ca.ca_state, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type
ORDER BY 
    total_customers DESC
LIMIT 10;
