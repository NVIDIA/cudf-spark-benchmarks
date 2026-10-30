
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_quantity) AS total_quantity_sold, 
    SUM(ss.ss_sales_price) AS total_sales_price, 
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales_price DESC
LIMIT 100;
