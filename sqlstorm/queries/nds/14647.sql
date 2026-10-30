
SELECT 
    c.c_customer_id,
    ca.ca_city,
    sum(ss.ss_sales_price) AS total_sales,
    count(ss.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 100;
