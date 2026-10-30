
SELECT 
    c.c_customer_id, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
    SUM(ws.ws_sales_price) AS total_sales,
    MAX(ws.ws_sold_date_sk) AS last_order_date
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    c.c_customer_id
HAVING 
    SUM(ws.ws_sales_price) > 10000
ORDER BY 
    total_sales DESC
LIMIT 
    100;
