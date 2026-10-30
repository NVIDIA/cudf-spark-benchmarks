
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_sales_price) AS avg_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 10
ORDER BY 
    total_sales DESC
LIMIT 100;
