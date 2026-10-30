
SELECT 
    c.c_customer_id, 
    ca.ca_city, 
    COUNT(ws.ws_order_number) AS total_orders, 
    SUM(ws.ws_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND c.c_birth_year > 1980
GROUP BY 
    c.c_customer_id, 
    ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
