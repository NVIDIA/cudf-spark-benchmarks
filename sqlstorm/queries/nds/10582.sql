
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions,
    AVG(ss.ss_sales_price) AS average_sale,
    MIN(ss.ss_sales_price) AS min_sale,
    MAX(ss.ss_sales_price) AS max_sale
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
HAVING 
    SUM(ss.ss_sales_price) > 1000
ORDER BY 
    total_sales DESC;
