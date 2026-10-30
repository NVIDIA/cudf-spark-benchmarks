
SELECT 
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    AVG(ws_net_profit) AS average_net_profit
FROM 
    web_sales
WHERE 
    ws_sold_date_sk BETWEEN 1 AND 365
GROUP BY 
    ws_ship_mode_sk
ORDER BY 
    total_sales DESC
LIMIT 10;
