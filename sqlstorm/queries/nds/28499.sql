
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_revenue,
    MAX(ws.ws_ship_date_sk) AS last_order_date,
    LEFT(REPLACE(c.c_email_address, '@', ' [at] '), 30) || '...' AS obfuscated_email
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    UPPER(c.c_last_name) LIKE 'A%' 
    AND ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, 
    LEFT(REPLACE(c.c_email_address, '@', ' [at] '), 30)
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_revenue DESC, c.c_last_name ASC, c.c_first_name ASC;
