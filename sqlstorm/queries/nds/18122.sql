
SELECT 
    c.c_customer_id, 
    ca.ca_city, 
    COUNT(ss.ss_ticket_number) AS sales_count
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    sales_count DESC
LIMIT 10;
