
SELECT 
    c.c_customer_id, 
    COUNT(ss.ss_ticket_number) AS total_sales, 
    SUM(ss.ss_net_paid) AS total_sales_amount
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_customer_id
HAVING 
    COUNT(ss.ss_ticket_number) > 10
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
