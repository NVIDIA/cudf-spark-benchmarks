
SELECT 
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_current_cdemo_sk IS NOT NULL
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
