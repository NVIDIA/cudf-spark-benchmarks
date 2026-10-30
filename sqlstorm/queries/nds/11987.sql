SELECT 
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    AVG(ws_ext_sales_price) AS average_order_value,
    ws_ship_mode_sk
FROM 
    web_sales
WHERE 
    ws_sold_date_sk BETWEEN 2450883 AND 2450920  
GROUP BY 
    ws_ship_mode_sk
ORDER BY 
    total_sales DESC;