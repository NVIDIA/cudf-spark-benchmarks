
SELECT 
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    AVG(ws_ext_sales_price) AS avg_sales_price,
    ws_ship_mode_sk
FROM 
    web_sales
WHERE 
    ws_sold_date_sk BETWEEN 10000 AND 10050
GROUP BY 
    ws_ship_mode_sk
ORDER BY 
    total_sales DESC;
