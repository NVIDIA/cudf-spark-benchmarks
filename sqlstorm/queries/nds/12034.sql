
SELECT 
    c.c_customer_id,
    ca.ca_country,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_country = 'USA'
GROUP BY 
    c.c_customer_id, ca.ca_country
ORDER BY 
    total_sales DESC
LIMIT 100;
