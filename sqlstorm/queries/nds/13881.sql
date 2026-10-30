
SELECT 
    c.c_customer_id,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    AVG(ss.ss_sales_price) AS avg_sale_price
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_net_profit DESC
LIMIT 100;
