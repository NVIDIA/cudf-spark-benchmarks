
SELECT 
    COUNT(*) AS total_sales,
    SUM(ws_net_paid) AS total_revenue,
    AVG(ws_net_paid) AS average_order_value,
    d_year,
    d_month_seq,
    d_day_name
FROM 
    web_sales
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
WHERE 
    d_year = 2023
GROUP BY 
    d_year, d_month_seq, d_day_name
ORDER BY 
    d_year, d_month_seq, d_day_name;
