
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    COUNT(ss.ss_ticket_number) AS sales_count, 
    SUM(ss.ss_net_paid) AS total_sales 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name 
ORDER BY 
    total_sales DESC 
LIMIT 100;
