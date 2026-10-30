
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS total_customers, 
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ca_state
ORDER BY 
    total_customers DESC
LIMIT 10;
