
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ss_ticket_number) AS total_transactions,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_net_profit) AS average_profit
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
