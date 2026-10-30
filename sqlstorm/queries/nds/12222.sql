
SELECT 
    w.w_warehouse_name, 
    SUM(ss.ss_sales_price) AS total_sales, 
    COUNT(ss.ss_ticket_number) AS total_transactions 
FROM 
    store_sales ss 
JOIN 
    warehouse w ON ss.ss_store_sk = w.w_warehouse_sk 
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE 
    d.d_year = 2023 
GROUP BY 
    w.w_warehouse_name 
ORDER BY 
    total_sales DESC 
LIMIT 10;
