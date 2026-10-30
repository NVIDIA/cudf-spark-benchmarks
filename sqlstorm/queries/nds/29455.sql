
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    STRING_AGG(i.i_item_desc, ', ') AS purchased_items
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state = 'CA'
    AND c.c_birth_month = 12
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_ext_sales_price) > 500
ORDER BY 
    total_spent DESC
LIMIT 10;
