
SELECT 
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions,
    MAX(ss.ss_sold_date_sk) AS last_purchase_date
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_birth_year >= 1980
GROUP BY 
    c.c_customer_id
HAVING 
    SUM(ss.ss_sales_price) > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
