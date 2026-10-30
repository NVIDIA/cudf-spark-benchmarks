
SELECT 
    COUNT(*) AS total_sales, 
    SUM(ws_sales_price) AS total_revenue, 
    AVG(ws_sales_price) AS avg_sales_price 
FROM 
    web_sales 
WHERE 
    ws_sold_date_sk BETWEEN 1 AND 30 
GROUP BY 
    ws_ship_mode_sk 
ORDER BY 
    total_revenue DESC;
