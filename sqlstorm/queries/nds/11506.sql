
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    addr.ca_city,
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_address addr ON c.c_current_addr_sk = addr.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    addr.ca_state = 'CA'
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, addr.ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
