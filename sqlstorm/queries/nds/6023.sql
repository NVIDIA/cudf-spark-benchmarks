
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ws.ws_sales_price) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
    d.d_year AS purchase_year,
    COUNT(DISTINCT ws.ws_ship_mode_sk) AS shipping_methods_used
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year IN (2022, 2023)
    AND ca.ca_state = 'CA'
    AND ws.ws_net_paid > 0
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    d.d_year
HAVING 
    SUM(ws.ws_sales_price) > 500
ORDER BY 
    total_spent DESC;
