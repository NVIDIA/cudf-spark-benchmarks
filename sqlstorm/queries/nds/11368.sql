
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ws.ws_sales_price) AS total_sales, 
    MAX(ws.ws_sales_price) AS max_sale_price, 
    MIN(ws.ws_sales_price) AS min_sale_price 
FROM 
    customer c 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk 
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31') 
GROUP BY 
    c.c_first_name, c.c_last_name 
ORDER BY 
    total_sales DESC 
LIMIT 100;
