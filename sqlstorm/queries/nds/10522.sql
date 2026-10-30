
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(ss_sales_price) AS total_sales,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_address
JOIN 
    customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN 
    store_sales ON store_sales.ss_customer_sk = customer.c_customer_sk
JOIN 
    customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
WHERE 
    ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC;
