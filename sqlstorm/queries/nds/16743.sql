
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    COUNT(ss.ss_ticket_number) AS total_purchases 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
GROUP BY 
    c.c_first_name, c.c_last_name 
ORDER BY 
    total_purchases DESC 
LIMIT 10;
