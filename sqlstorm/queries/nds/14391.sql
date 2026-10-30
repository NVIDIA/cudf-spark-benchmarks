
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_id) AS customer_count, 
    SUM(ss_sales_price) AS total_sales 
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
GROUP BY 
    ca_city 
ORDER BY 
    total_sales DESC 
LIMIT 10;
