
SELECT 
    c.c_customer_id, 
    SUM(ws.ws_sales_price) AS total_sales, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
    AVG(ws.ws_sales_price) AS average_order_value, 
    MIN(ws.ws_sales_price) AS min_order_value, 
    MAX(ws.ws_sales_price) AS max_order_value 
FROM 
    customer c 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
WHERE 
    ws.ws_sold_date_sk BETWEEN 1 AND 365 
GROUP BY 
    c.c_customer_id 
ORDER BY 
    total_sales DESC 
LIMIT 100;
