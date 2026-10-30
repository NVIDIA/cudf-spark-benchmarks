
SELECT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    SUM(ws.ws_sales_price) AS total_sales
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'NY'
GROUP BY 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state
HAVING 
    SUM(ws.ws_sales_price) > 1000
ORDER BY 
    total_sales DESC;
