
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ss_ticket_number) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    AVG(ss_sales_price) AS average_price,
    MAX(ss_sales_price) AS max_price
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1970 AND 2000
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_profit DESC
LIMIT 1000;
