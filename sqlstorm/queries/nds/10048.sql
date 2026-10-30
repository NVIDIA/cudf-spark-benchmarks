
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_id) AS unique_customers, 
    SUM(ss_sales_price) AS total_sales
FROM 
    customer_address ca 
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    ca_state = 'CA' 
    AND ss.ss_sold_date_sk BETWEEN 1 AND 500 
GROUP BY 
    ca_city 
ORDER BY 
    total_sales DESC 
LIMIT 10;
