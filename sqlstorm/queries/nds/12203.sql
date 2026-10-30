
SELECT 
    w.w_warehouse_id,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    web_sales ws
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    w.w_warehouse_id
ORDER BY 
    total_sales DESC
LIMIT 10;
