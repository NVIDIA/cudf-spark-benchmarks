
SELECT 
    c.c_customer_id,
    COUNT(s.ss_ticket_number) AS total_sales,
    SUM(s.ss_net_profit) AS total_net_profit,
    AVG(s.ss_sales_price) AS avg_sales_price
FROM 
    customer c
JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk
JOIN 
    date_dim d ON s.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_net_profit DESC
LIMIT 10;
