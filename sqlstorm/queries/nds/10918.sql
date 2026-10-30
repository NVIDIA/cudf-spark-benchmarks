
SELECT 
    c.c_customer_id,
    ca.ca_city, 
    ca.ca_state, 
    COUNT(ws.ws_order_number) AS total_orders, 
    SUM(ws.ws_ext_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND ws.ws_sold_date_sk BETWEEN 2458849 AND 2458880
GROUP BY 
    c.c_customer_id, ca.ca_city, ca.ca_state
ORDER BY 
    total_sales DESC 
LIMIT 100;
