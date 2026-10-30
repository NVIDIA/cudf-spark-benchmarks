
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ss_ticket_number) AS total_purchases,
    SUM(ss_sales_price) AS total_spent,
    AVG(ss_sales_price) AS average_spend
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_birth_year > 1980
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_spent DESC
LIMIT 100;
