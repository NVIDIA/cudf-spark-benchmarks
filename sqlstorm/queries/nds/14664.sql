
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(ws.ws_order_number) AS total_orders, 
    SUM(ws.ws_net_paid) AS total_spent
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state 
ORDER BY 
    total_spent DESC 
LIMIT 10;
