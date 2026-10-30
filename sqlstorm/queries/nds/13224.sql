
SELECT 
    c.c_customer_id,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(ws.ws_order_number) AS order_count,
    AVG(ws.ws_net_profit) AS avg_net_profit
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
