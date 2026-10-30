
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    COUNT(ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_sales_price) AS total_revenue
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1970 AND 2000
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, c.c_email_address
HAVING 
    COUNT(ss.ss_ticket_number) > 10
ORDER BY 
    total_revenue DESC
LIMIT 50;
