
SELECT 
    COUNT(*) as total_sales, 
    SUM(ws_ext_sales_price) as total_revenue
FROM 
    web_sales 
WHERE 
    ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-31')
GROUP BY 
    ws_web_site_sk 
ORDER BY 
    total_revenue DESC;
