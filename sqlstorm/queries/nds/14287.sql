
SELECT 
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS order_count,
    AVG(ws_net_profit) AS average_net_profit
FROM 
    web_sales
WHERE 
    ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
    AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
GROUP BY 
    ws_web_site_sk
ORDER BY 
    total_sales DESC
LIMIT 10;
