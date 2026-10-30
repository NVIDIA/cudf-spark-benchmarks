
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ss.ss_sales_price) AS total_sales,
    dd.d_year, 
    dd.d_month_seq
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, dd.d_year, dd.d_month_seq
ORDER BY 
    total_sales DESC
LIMIT 100;
