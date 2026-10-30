
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid_inc_tax) AS average_order_value,
    d.d_year,
    d.d_month_seq,
    sm.sm_carrier
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    d.d_year = 2022
    AND ws.ws_net_profit > 0
GROUP BY 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    d.d_month_seq,
    sm.sm_carrier
HAVING 
    COUNT(ws.ws_order_number) > 5
ORDER BY 
    total_profit DESC
LIMIT 10;
