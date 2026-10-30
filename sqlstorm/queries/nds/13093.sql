
SELECT 
    c.c_customer_id, 
    SUM(ws.ws_net_paid) AS total_spent, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders 
FROM 
    customer c 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
WHERE 
    c.c_birth_year >= 1980 
GROUP BY 
    c.c_customer_id 
ORDER BY 
    total_spent DESC 
LIMIT 100;
