
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_id) AS customer_count, 
    SUM(ss_sales_price) AS total_sales
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
