
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS num_customers, 
    AVG(cd_purchase_estimate) AS avg_purchase_estimate 
FROM 
    customer_address 
JOIN 
    customer ON customer.c_current_addr_sk = customer_address.ca_address_sk 
JOIN 
    customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk 
GROUP BY 
    ca_state 
ORDER BY 
    num_customers DESC 
LIMIT 10;
