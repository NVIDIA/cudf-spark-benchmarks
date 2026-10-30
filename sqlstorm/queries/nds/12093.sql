SELECT 
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    AVG(ss.ss_quantity) AS avg_quantity_per_transaction
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 2000000 AND 2001000 
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;