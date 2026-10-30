
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_sales_price) AS total_sales_amount,
    AVG(ss.ss_sales_price) AS average_sales_price
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'CA'
    AND ss.ss_sold_date_sk BETWEEN 2400 AND 2600
GROUP BY 
    c.c_customer_id, 
    ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 100;
