
SELECT 
    c.c_customer_id, 
    SUM(ws.ws_sales_price) AS total_sales, 
    COUNT(ws.ws_order_number) AS total_orders,
    COUNT(DISTINCT ws.ws_item_sk) AS unique_items
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN 2450000 AND 2450020
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
