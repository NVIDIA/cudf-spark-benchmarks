
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS unique_customers, 
    SUM(ws_sales_price) AS total_sales
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca_state IS NOT NULL AND 
    ws.ws_sales_price > 0
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;
