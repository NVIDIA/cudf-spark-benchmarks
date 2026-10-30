
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
    SUM(s.ss_sales_price) AS total_sales_amount,
    AVG(s.ss_net_profit) AS average_net_profit,
    d.d_year
FROM 
    customer c
JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk
JOIN 
    date_dim d ON s.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    c.c_customer_id, d.d_year
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
