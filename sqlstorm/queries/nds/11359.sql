
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_sales_price) AS total_sales,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COUNT(ss.ss_ticket_number) AS total_transactions
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 1 AND 365
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY 
    total_sales DESC
LIMIT 10;
