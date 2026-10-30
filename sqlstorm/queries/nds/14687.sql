
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS num_customers,
    SUM(ws_quantity) AS total_sales,
    AVG(ws_net_profit) AS avg_net_profit
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC;
