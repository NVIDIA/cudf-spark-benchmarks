
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_ext_sales_price) AS total_sales, 
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    ss.ss_sold_date_sk BETWEEN 1 AND 365 
GROUP BY 
    c.c_customer_id 
ORDER BY 
    total_sales DESC 
LIMIT 100;
