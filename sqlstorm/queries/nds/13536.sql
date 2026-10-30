
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_profit) AS total_profit
FROM 
    customer AS c
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN 2451545 AND 2451546
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY 
    total_profit DESC
LIMIT 100;
