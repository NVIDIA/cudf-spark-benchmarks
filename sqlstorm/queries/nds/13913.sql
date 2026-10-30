
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    AVG(ws.ws_net_paid) AS average_order_value,
    MAX(ws.ws_sold_date_sk) AS last_order_date
FROM
    customer c
JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
WHERE
    ws.ws_sold_date_sk >= 20200101
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_spent DESC
LIMIT 100;
