
SELECT 
    COUNT(*) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    AVG(ws_sales_price) AS average_sales_price,
    MAX(ws_sales_price) AS max_sales_price,
    MIN(ws_sales_price) AS min_sales_price
FROM 
    web_sales
JOIN 
    date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
WHERE 
    date_dim.d_year = 2023
GROUP BY 
    date_dim.d_month_seq
ORDER BY 
    date_dim.d_month_seq;
