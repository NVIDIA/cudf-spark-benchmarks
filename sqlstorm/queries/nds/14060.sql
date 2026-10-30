
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ss_sales_price) AS total_sales
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca_state = 'NY'
GROUP BY 
    ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
