
SELECT 
    c.c_customer_id, 
    COUNT(ss.ss_ticket_number) AS total_sales, 
    SUM(ss.ss_net_profit) AS total_profit
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
    AND ss.ss_sold_date_sk BETWEEN 2458830 AND 2458920
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_profit DESC
LIMIT 100;
