
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    ca.ca_city,
    ca.ca_state,
    c.c_email_address,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    AVG(ws.ws_ext_sales_price) AS avg_order_value,
    MAX(ws.ws_sold_date_sk) AS last_order_date
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'TX', 'NY')
    AND c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    customer_name, ca.ca_city, ca.ca_state, c.c_email_address
ORDER BY 
    total_spent DESC
LIMIT 10;
