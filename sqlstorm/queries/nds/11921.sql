
SELECT 
    SUM(ws_net_profit) AS total_net_profit, 
    COUNT(DISTINCT ws_order_number) AS total_orders, 
    AVG(ws_quantity) AS avg_quantity_per_order
FROM 
    web_sales 
WHERE 
    ws_sold_date_sk BETWEEN 1 AND 365 
GROUP BY 
    ws_ship_mode_sk 
ORDER BY 
    total_net_profit DESC;
