
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
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
    c.c_customer_id, c.c_first_name, c.c_last_name, s.s_store_name
HAVING 
    SUM(ss.ss_sales_price) > 1000
ORDER BY 
    total_sales DESC;
