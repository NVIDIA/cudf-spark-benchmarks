
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    COUNT(ss.ss_ticket_number) AS total_sales
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_first_name, 
    c.c_last_name
ORDER BY 
    total_sales DESC
LIMIT 10;
