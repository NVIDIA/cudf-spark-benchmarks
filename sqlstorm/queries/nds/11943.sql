
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ws.ws_sales_price, 
    SUM(ss.ss_quantity) AS total_sales_quantity
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    web_sales ws ON ss.ss_item_sk = ws.ws_item_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ws.ws_sales_price
ORDER BY 
    total_sales_quantity DESC
LIMIT 100;
