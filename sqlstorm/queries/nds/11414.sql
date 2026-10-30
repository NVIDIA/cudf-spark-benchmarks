
SELECT 
    SUM(ws_ext_sales_price) AS total_sales, 
    d_year, 
    d_month_seq 
FROM 
    web_sales 
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk 
GROUP BY 
    d_year, d_month_seq 
ORDER BY 
    d_year, d_month_seq;
