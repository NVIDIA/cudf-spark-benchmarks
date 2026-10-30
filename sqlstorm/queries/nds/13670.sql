
SELECT 
    c.c_customer_id,
    s.s_store_name,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    AVG(ss.ss_sales_price) AS average_sales_price
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    store AS s ON ss.ss_store_sk = s.s_store_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 1 AND 10
GROUP BY 
    c.c_customer_id, s.s_store_name
ORDER BY 
    total_sales DESC
LIMIT 100;
