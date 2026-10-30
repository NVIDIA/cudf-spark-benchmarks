
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_id) AS customer_count, 
    AVG(cd_purchase_estimate) AS average_purchase_estimate
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    ca_state
ORDER BY 
    customer_count DESC
LIMIT 10;
