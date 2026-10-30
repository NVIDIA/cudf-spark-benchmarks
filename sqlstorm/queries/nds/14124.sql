
SELECT 
    c.c_customer_id,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(ss.ss_ticket_number) AS total_sales,
    AVG(ss.ss_sales_price) AS avg_sales_price
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_net_profit DESC
LIMIT 10;
