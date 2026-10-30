
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    COUNT(ss.ss_ticket_number) AS total_sales, 
    SUM(ss.ss_net_paid) AS total_spent 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990 
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name 
ORDER BY 
    total_spent DESC 
LIMIT 100;
