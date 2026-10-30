
SELECT 
    SUM(ws_quantity) AS total_quantity_sold,
    SUM(ws_sales_price) AS total_sales_amount,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    d_year,
    d_month_seq
FROM 
    web_sales
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
WHERE 
    d_year = 2022
GROUP BY 
    d_year, d_month_seq
ORDER BY 
    d_year, d_month_seq;
