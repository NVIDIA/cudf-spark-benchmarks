
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(ss.ss_ticket_number) AS total_transactions,
    AVG(ss.ss_sales_price) AS average_sales_price
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_net_profit DESC
LIMIT 100;
