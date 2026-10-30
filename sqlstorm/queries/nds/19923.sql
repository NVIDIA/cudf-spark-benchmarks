
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    SUM(ss.ss_quantity) AS total_quantity_sold 
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city 
ORDER BY 
    total_quantity_sold DESC 
LIMIT 10;
