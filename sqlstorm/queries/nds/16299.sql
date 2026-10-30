
SELECT 
    c.c_customer_id, 
    a.ca_city, 
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id, a.ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
