
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
    ca.ca_city, 
    ca.ca_state, 
    COALESCE(d.d_day_name, 'Unknown') AS day_name, 
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    MAX(ws.ws_sales_price) AS max_order_value,
    MIN(ws.ws_sales_price) AS min_order_value
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_year > 1980 
    AND ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    full_name, ca.ca_city, ca.ca_state, d.d_day_name
HAVING 
    COUNT(ws.ws_order_number) > 5 
ORDER BY 
    total_spent DESC;
