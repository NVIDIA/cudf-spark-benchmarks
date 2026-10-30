
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    COUNT(ws.ws_order_number) AS total_orders, 
    SUM(ws.ws_net_paid) AS total_spent 
FROM 
    customer c 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
WHERE 
    d.d_year = 2022 
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name 
ORDER BY 
    total_spent DESC 
LIMIT 10;
