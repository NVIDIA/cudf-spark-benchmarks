
SELECT 
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    SUM(ss.ss_quantity) AS total_sales,
    SUM(ss.ss_sales_price) AS total_revenue
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    store AS s ON ss.ss_store_sk = s.s_store_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_first_name, c.c_last_name, s.s_store_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
