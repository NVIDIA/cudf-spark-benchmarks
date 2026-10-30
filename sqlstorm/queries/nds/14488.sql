
SELECT 
    d.d_year, 
    s.s_store_id, 
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    store_sales ss
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    d.d_year, s.s_store_id
ORDER BY 
    total_sales DESC
LIMIT 10;
