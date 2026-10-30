
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_sales_price) AS total_sales 
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990 
GROUP BY 
    c.c_customer_id 
ORDER BY 
    total_sales DESC 
LIMIT 10;
