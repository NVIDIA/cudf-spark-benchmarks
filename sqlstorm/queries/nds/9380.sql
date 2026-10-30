
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    d.d_year,
    d.d_month_seq,
    d.d_quarter_seq,
    p.p_promo_id,
    sm.sm_type AS shipping_mode,
    ca.ca_city,
    ca.ca_state
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    d.d_year = 2023 
    AND p.p_discount_active = 'Y'
    AND ca.ca_state IN ('CA', 'NY')
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq, d.d_quarter_seq, p.p_promo_id, sm.sm_type, ca.ca_city, ca.ca_state
ORDER BY 
    total_sales DESC
LIMIT 100;
