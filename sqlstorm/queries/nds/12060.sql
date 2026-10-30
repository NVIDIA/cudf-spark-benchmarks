
SELECT 
    c.c_customer_id,
    SUM(ss.ss_net_paid) AS total_spent,
    COUNT(ss.ss_ticket_number) AS total_purchases,
    AVG(ss.ss_net_profit) AS average_profit
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_spent DESC
LIMIT 100;
