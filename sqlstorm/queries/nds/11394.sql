
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS transaction_count
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_state = 'NY' AND 
    ss.ss_sold_date_sk BETWEEN 2451524 AND 2451621
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
