
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    SUM(ss.ss_ext_sales_price) AS total_sales 
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city 
HAVING 
    SUM(ss.ss_ext_sales_price) > 1000 
ORDER BY 
    total_sales DESC 
LIMIT 10;
