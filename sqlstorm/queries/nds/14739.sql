
SELECT 
    COUNT(*) AS total_sales,
    SUM(ws_net_profit) AS total_net_profit,
    AVG(ws_sales_price) AS average_sales_price,
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
