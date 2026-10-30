
SELECT 
    c.c_customer_id, 
    SUM(s.ss_sales_price) AS total_sales, 
    COUNT(s.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk
WHERE 
    s.ss_sold_date_sk BETWEEN 1000 AND 1500
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 10;
