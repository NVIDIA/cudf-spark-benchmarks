
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ss_sales_price) AS total_sales,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk 
JOIN 
    store_sales ON c_customer_sk = ss_customer_sk 
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk
GROUP BY 
    ca_state 
ORDER BY 
    total_sales DESC 
LIMIT 10;
