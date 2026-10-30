
SELECT 
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    AVG(ws_sales_price) AS average_sales_price,
    ws_ship_mode_sk
FROM 
    web_sales
WHERE 
    ws_sold_date_sk BETWEEN 1000 AND 2000
GROUP BY 
    ws_ship_mode_sk
ORDER BY 
    total_sales DESC
LIMIT 10;
