
SELECT 
    SUM(ws_ext_sales_price) AS total_sales, 
    COUNT(DISTINCT ws_order_number) AS total_orders, 
    AVG(ws_net_profit) AS average_profit
FROM 
    web_sales 
WHERE 
    ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
GROUP BY 
    ws_web_site_sk
ORDER BY 
    total_sales DESC
LIMIT 10;
