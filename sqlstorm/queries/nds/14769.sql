
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ss.ss_quantity, 
    ss.ss_sales_price 
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    ca.ca_state = 'CA' 
    AND ss.ss_sold_date_sk BETWEEN 20200101 AND 20201231 
ORDER BY 
    ss.ss_sales_price DESC 
LIMIT 100;
