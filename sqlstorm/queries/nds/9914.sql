
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ws.ws_net_profit) AS total_net_profit, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
    d.d_year, 
    w.w_warehouse_name, 
    sm.sm_type AS shipping_method
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    d.d_year BETWEEN 2021 AND 2023 
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    d.d_year, 
    w.w_warehouse_name, 
    sm.sm_type
HAVING 
    SUM(ws.ws_net_profit) > 1000
ORDER BY 
    total_net_profit DESC, 
    total_orders DESC;
