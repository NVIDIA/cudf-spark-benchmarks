
SELECT 
    c.c_customer_id, 
    SUM(ws.ws_sales_price) AS total_sales, 
    COUNT(DISTINCT(ws.ws_order_number)) AS number_of_orders,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    d.d_year
FROM 
    customer AS c
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, d.d_year
ORDER BY 
    total_sales DESC
LIMIT 100;
