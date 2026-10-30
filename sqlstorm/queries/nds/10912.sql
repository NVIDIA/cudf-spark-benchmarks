SELECT 
    c.c_first_name, 
    c.c_last_name, 
    a.ca_city, 
    a.ca_state, 
    SUM(ws.ws_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    a.ca_state = 'CA' 
    AND ws.ws_sold_date_sk BETWEEN 2459582 AND 2459588 
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    a.ca_city, 
    a.ca_state
ORDER BY 
    total_sales DESC
LIMIT 100;