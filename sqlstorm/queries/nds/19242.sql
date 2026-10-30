
SELECT 
    SUM(ws_ext_sales_price) as total_sales, 
    d_year 
FROM 
    web_sales 
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk 
GROUP BY 
    d_year 
ORDER BY 
    d_year;
