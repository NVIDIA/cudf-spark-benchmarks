
SELECT 
    SUM(ws_net_profit) AS total_net_profit,
    d_year
FROM 
    web_sales
JOIN 
    date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
GROUP BY 
    d_year
ORDER BY 
    d_year;
