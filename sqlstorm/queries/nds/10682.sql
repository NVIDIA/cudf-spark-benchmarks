
SELECT 
    ca_city, 
    COUNT(c_customer_sk) AS customer_count, 
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_address 
JOIN 
    customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN 
    customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
GROUP BY 
    ca_city
ORDER BY 
    customer_count DESC
LIMIT 10;
