
SELECT 
    COUNT(*) AS total_sales,
    SUM(ws_sales_price) AS total_revenue,
    AVG(ws_sales_price) AS average_sales_price,
    ws_ship_mode_sk,
    d_year
FROM 
    web_sales
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
GROUP BY 
    ws_ship_mode_sk, d_year
ORDER BY 
    total_revenue DESC
LIMIT 10;
