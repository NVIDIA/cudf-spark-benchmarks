
SELECT 
    c.c_customer_id, 
    s.s_store_name, 
    SUM(ss.ss_quantity) AS total_quantity_sold, 
    SUM(ss.ss_sales_price) AS total_sales 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk 
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990 
GROUP BY 
    c.c_customer_id, s.s_store_name 
ORDER BY 
    total_sales DESC 
LIMIT 10;
