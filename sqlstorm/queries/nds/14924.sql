
SELECT 
    c.c_customer_id, 
    ca.ca_zip, 
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'NY'
    AND ss.ss_sold_date_sk BETWEEN 2458170 AND 2458200
GROUP BY 
    c.c_customer_id, ca.ca_zip
ORDER BY 
    total_sales DESC
LIMIT 100;
