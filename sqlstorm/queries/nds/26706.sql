
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_sales_price) AS average_order_value,
    MIN(ws.ws_sold_date_sk) AS first_order_date,
    MAX(ws.ws_sold_date_sk) AS last_order_date
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX') 
    AND c.c_birth_year BETWEEN 1980 AND 1999
GROUP BY 
    customer_full_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(ws.ws_order_number) > 5
ORDER BY 
    total_sales DESC
LIMIT 10;
