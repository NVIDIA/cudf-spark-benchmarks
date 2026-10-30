
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_sales_price) AS total_revenue,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    MAX(ss.ss_sales_price) AS max_sales_price
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 1000 AND 2000
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_revenue DESC
LIMIT 10;
