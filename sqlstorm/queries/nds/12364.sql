
SELECT 
    c.c_customer_id,
    COUNT(ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_sales_price) AS total_sales_amount,
    AVG(ss.ss_net_profit) AS average_net_profit
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
