
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    COUNT(ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_sales_price) AS total_revenue
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_city = 'Los Angeles'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city
ORDER BY 
    total_revenue DESC
LIMIT 10;
