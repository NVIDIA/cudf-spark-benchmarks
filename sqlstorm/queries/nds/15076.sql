
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ws.ws_sold_date_sk,
    SUM(ws.ws_quantity) AS total_quantity
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ws.ws_sold_date_sk
ORDER BY 
    total_quantity DESC
LIMIT 10;
