
SELECT 
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    AVG(ss.ss_net_profit) AS average_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS number_of_purchases
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 10;
