
SELECT 
    c.c_first_name,
    c.c_last_name,
    sa.ca_city,
    sa.ca_state,
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_address sa ON c.c_current_addr_sk = sa.ca_address_sk
WHERE 
    sa.ca_state = 'CA'
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    sa.ca_city, 
    sa.ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;
