
SELECT 
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions,
    AVG(ss.ss_sales_price) AS average_sales_price,
    MAX(ss.ss_sales_price) AS max_sales_price,
    MIN(ss.ss_sales_price) AS min_sales_price
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 1000 AND 2000
GROUP BY 
    c.c_customer_id
HAVING 
    SUM(ss.ss_sales_price) > 10000
ORDER BY 
    total_sales DESC
LIMIT 10;
