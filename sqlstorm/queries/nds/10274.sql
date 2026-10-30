
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_net_paid) AS total_sales, 
    COUNT(ss.ss_ticket_number) AS number_of_transactions, 
    d.d_year 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE 
    d.d_year BETWEEN 2020 AND 2023 
GROUP BY 
    c.c_customer_id, d.d_year 
ORDER BY 
    total_sales DESC 
LIMIT 10;
