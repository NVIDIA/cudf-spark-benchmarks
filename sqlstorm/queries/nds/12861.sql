
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(ss.ss_ticket_number) AS total_sales
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
WHERE 
    s.s_state = 'CA'
GROUP BY 
    c.c_first_name, c.c_last_name
ORDER BY 
    total_profit DESC
LIMIT 10;
