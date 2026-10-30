
SELECT 
    c.c_customer_id,
    ca.ca_city,
    s.s_store_name,
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
WHERE 
    ca.ca_state = 'CA'
    AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2452045
GROUP BY 
    c.c_customer_id, ca.ca_city, s.s_store_name
ORDER BY 
    total_sales DESC
LIMIT 10;
