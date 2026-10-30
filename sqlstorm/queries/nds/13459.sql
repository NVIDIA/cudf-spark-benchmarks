
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_sk) AS customer_count, 
    SUM(ss_quantity) AS total_sales_quantity, 
    SUM(ss_net_paid) AS total_sales_amount 
FROM 
    customer_address AS ca 
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk 
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    ca.ca_state = 'CA' 
GROUP BY 
    ca_city 
ORDER BY 
    total_sales_amount DESC 
LIMIT 10;
