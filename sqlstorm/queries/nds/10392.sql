
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    COUNT(ws.ws_order_number) AS total_orders, 
    SUM(ws.ws_net_profit) AS total_profit
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1970 AND 1990
GROUP BY 
    c.c_first_name, c.c_last_name
ORDER BY 
    total_profit DESC
LIMIT 100;
