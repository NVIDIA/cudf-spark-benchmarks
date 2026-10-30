
SELECT 
    COUNT(*) AS total_sales,
    SUM(ws_sales_price) AS total_revenue,
    AVG(ws_net_profit) AS average_profit
FROM 
    web_sales
WHERE 
    ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
    AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    AND ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'AIR')
GROUP BY 
    ws_item_sk
ORDER BY 
    total_revenue DESC
LIMIT 10;
