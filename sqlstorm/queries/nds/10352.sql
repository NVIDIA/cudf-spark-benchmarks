
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ws.ws_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city
HAVING 
    SUM(ws.ws_sales_price) > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
