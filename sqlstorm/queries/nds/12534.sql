
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    a.ca_city,
    s.s_store_name,
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
WHERE 
    a.ca_state = 'CA'
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city, s.s_store_name
ORDER BY 
    total_sales DESC
LIMIT 10;
