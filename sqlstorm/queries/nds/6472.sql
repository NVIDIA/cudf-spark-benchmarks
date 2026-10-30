
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_sales_price) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    d.d_year,
    d.d_month_seq,
    ca.ca_city,
    ca.ca_state,
    sm.sm_type
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    d.d_year = 2023
    AND ca.ca_state = 'CA'
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name,
    d.d_year, d.d_month_seq, ca.ca_city, ca.ca_state, sm.sm_type
HAVING 
    SUM(ws.ws_quantity) > 10
ORDER BY 
    total_spent DESC
LIMIT 100;
