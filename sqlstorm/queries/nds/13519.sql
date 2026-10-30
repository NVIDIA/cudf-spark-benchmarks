
SELECT 
    SUM(ws_ext_sales_price) AS total_sales, 
    COUNT(DISTINCT ws_order_number) AS total_orders, 
    w_warehouse_name 
FROM 
    web_sales 
JOIN 
    warehouse ON ws_warehouse_sk = w_warehouse_sk 
WHERE 
    ws_sold_date_sk BETWEEN 2451545 AND 2451546 
GROUP BY 
    w_warehouse_name 
ORDER BY 
    total_sales DESC 
LIMIT 10;
