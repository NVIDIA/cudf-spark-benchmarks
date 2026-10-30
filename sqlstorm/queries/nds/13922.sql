
SELECT 
    SUM(ws_sales_price) AS total_sales, 
    COUNT(DISTINCT ws_order_number) AS total_orders, 
    AVG(ws_sales_price) AS average_order_value 
FROM 
    web_sales 
WHERE 
    ws_sold_date_sk BETWEEN 1 AND 100 
GROUP BY 
    ws_ship_mode_sk 
ORDER BY 
    total_sales DESC;
