
SELECT 
    c.c_customer_id,
    COUNT(ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_net_paid) AS total_revenue,
    AVG(ss.ss_net_profit) AS average_profit
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_revenue DESC
LIMIT 100;
