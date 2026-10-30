
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(sr_return_quantity) AS total_returns,
    AVG(ws_sales_price) AS avg_sales_price
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
GROUP BY 
    ca_state
ORDER BY 
    total_customers DESC
LIMIT 10;
