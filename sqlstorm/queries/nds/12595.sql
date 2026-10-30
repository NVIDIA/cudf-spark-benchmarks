
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(ws_quantity) AS total_sales_quantity,
    SUM(ws_sales_price) AS total_sales_amount
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    ca_state
ORDER BY 
    total_sales_amount DESC;
