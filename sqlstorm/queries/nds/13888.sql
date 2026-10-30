
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ws.ws_net_paid) AS total_spent, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders 
FROM 
    customer c 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
WHERE 
    ws.ws_sold_date_sk BETWEEN 1000 AND 2000 
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name 
ORDER BY 
    total_spent DESC 
LIMIT 10;
