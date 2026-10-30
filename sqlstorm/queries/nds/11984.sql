
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_revenue,
    AVG(ws.ws_sales_price) AS average_order_value,
    MAX(ws.ws_sales_price) AS max_order_value,
    MIN(ws.ws_sales_price) AS min_order_value
FROM 
    customer AS c
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_revenue DESC
LIMIT 100;
