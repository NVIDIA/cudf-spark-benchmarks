
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COUNT(*) AS total_orders,
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    SUM(ss.ss_sales_price) > 10000
ORDER BY 
    total_orders DESC
LIMIT 100;
