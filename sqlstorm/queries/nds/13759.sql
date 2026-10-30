
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    ws.ws_sales_price, 
    ws.ws_quantity 
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
WHERE 
    ca.ca_state = 'CA' 
    AND ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231 
ORDER BY 
    ws.ws_sales_price DESC 
LIMIT 100;
