
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_sales_price) AS total_sales, 
    COUNT(ss.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
AND 
    ss.ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_month_seq = 6 LIMIT 1)
AND 
    (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_month_seq = 7 LIMIT 1)
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
