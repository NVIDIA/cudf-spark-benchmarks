
SELECT 
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS number_of_sales,
    AVG(ss.ss_sales_price) AS avg_sales_price
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 1000 AND 2000
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
