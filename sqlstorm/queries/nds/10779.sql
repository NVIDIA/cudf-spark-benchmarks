
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(ss.ss_ticket_number) AS total_sales_count,
    COUNT(DISTINCT ss.ss_store_sk) AS total_stores
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 2450000 AND 2455000
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_net_profit DESC
LIMIT 100;
