
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
    d.d_year,
    d.d_month_seq,
    d.d_week_seq,
    sm.sm_type AS shipping_method,
    COUNT(DISTINCT ws.ws_item_sk) AS total_items_sold
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    d.d_year = 2023
    AND d.d_month_seq BETWEEN 1 AND 6
GROUP BY 
    c.c_customer_id, ca.ca_city, d.d_year, d.d_month_seq, d.d_week_seq, sm.sm_type
ORDER BY 
    total_revenue DESC
LIMIT 100;
