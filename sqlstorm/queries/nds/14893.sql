
SELECT 
    d.d_year, 
    SUM(ss.ss_sales_price) AS total_sales 
FROM 
    store_sales ss 
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk 
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk 
WHERE 
    d.d_year BETWEEN 2020 AND 2023 
    AND s.s_state = 'CA' 
GROUP BY 
    d.d_year 
ORDER BY 
    d.d_year;
