
SELECT 
    d.d_month_seq,
    d.d_year,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_sales_price) AS avg_sales_price
FROM 
    web_sales AS ws
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
GROUP BY 
    d.d_month_seq, d.d_year
ORDER BY 
    d.d_year, d.d_month_seq;
