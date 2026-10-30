
SELECT 
    c.c_customer_id,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_sales_price) AS total_sales_amount,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN 1 AND 10000
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
