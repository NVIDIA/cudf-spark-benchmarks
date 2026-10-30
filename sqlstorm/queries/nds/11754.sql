
SELECT 
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    d.d_year,
    w.w_warehouse_id
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, d.d_year, w.w_warehouse_id
ORDER BY 
    total_sales DESC
LIMIT 100;
