
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    customer AS c
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name
ORDER BY 
    total_net_profit DESC
LIMIT 10;
