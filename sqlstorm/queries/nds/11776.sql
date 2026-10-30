
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_sales_price) AS total_sales, 
    COUNT(ss.ss_ticket_number) AS total_transactions 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    c.c_birth_year BETWEEN 1980 AND 2000 
    AND ss.ss_sold_date_sk = (SELECT MAX(ss1.ss_sold_date_sk) FROM store_sales ss1) 
GROUP BY 
    c.c_customer_id 
ORDER BY 
    total_sales DESC 
LIMIT 10;
