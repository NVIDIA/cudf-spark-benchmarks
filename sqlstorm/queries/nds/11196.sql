
SELECT 
    w.w_warehouse_id,
    SUM(cs.cs_sales_price) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    AVG(cs.cs_sales_price) AS avg_sales_price
FROM 
    warehouse w
JOIN 
    catalog_sales cs ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN 
    date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    w.w_warehouse_id
ORDER BY 
    total_sales DESC;
