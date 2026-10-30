
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid_inc_tax) AS avg_payment
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
    AND ca.ca_state = 'CA'
    AND ws.ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'Express')
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    SUM(ws.ws_quantity) > 100
ORDER BY 
    total_profit DESC
LIMIT 10;
