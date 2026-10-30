
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_email_address,
    a.ca_city,
    a.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    MAX(ws.ws_sold_date_sk) AS last_purchase_date
FROM 
    customer c
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
    AND a.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address, a.ca_city, a.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC
LIMIT 100;
