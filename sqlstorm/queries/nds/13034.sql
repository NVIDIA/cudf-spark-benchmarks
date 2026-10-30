
SELECT 
    c.c_customer_id, 
    SUM(ss_ext_sales_price) AS total_sales, 
    COUNT(ss_ticket_number) AS total_transactions
FROM 
    customer AS c
JOIN 
    store_sales AS s ON c.c_customer_sk = s.ss_customer_sk
WHERE 
    c.c_birth_year > 1980
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC;
