
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_id) AS total_customers, 
    SUM(ss_sales_price) AS total_sales
FROM 
    customer_address
JOIN 
    customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN 
    store_sales ON store_sales.ss_customer_sk = customer.c_customer_sk
WHERE 
    ca_state = 'CA'
GROUP BY 
    ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
