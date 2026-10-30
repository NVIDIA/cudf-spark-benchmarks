
SELECT 
    c.c_customer_id, 
    ca.ca_city, 
    avg(ws.ws_sales_price) AS avg_sales_price
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    avg_sales_price DESC
LIMIT 10;
