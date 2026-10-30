
SELECT 
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
    AVG(ss.ss_sales_price) AS average_sales_price,
    MAX(ss.ss_sales_price) AS max_sales_price,
    MIN(ss.ss_sales_price) AS min_sales_price
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 1 AND 100
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 10;
