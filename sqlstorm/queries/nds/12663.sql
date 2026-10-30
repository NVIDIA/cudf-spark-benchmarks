
SELECT 
    SUM(ws_net_paid) AS total_sales, 
    d_year
FROM 
    web_sales 
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk 
WHERE 
    d_year BETWEEN 2020 AND 2023 
GROUP BY 
    d_year 
ORDER BY 
    d_year;
