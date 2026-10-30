
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_sales_price) AS total_sales,
    d.d_year,
    w.w_warehouse_name
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    warehouse AS w ON ss.ss_store_sk = w.w_warehouse_sk
WHERE 
    d.d_year = 2022
GROUP BY 
    c.c_first_name, c.c_last_name, d.d_year, w.w_warehouse_name
ORDER BY 
    total_sales DESC
LIMIT 10;
