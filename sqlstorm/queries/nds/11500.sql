
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_net_paid) AS total_sales, 
    AVG(ss.ss_sales_price) AS average_sales_price, 
    COUNT(ss.ss_ticket_number) AS total_transactions 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) 
GROUP BY 
    c.c_customer_id 
ORDER BY 
    total_sales DESC 
LIMIT 10;
