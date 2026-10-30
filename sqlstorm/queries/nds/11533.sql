
SELECT 
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    AVG(ws_sales_price) AS average_sales_price,
    SUM(ws_quantity) AS total_quantity_sold
FROM 
    web_sales
JOIN 
    date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
WHERE 
    d_year = 2023
GROUP BY 
    d_month_seq
ORDER BY 
    d_month_seq;
