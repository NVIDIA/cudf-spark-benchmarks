
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS num_customers, 
    SUM(ws_net_profit) AS total_profit
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT c_customer_sk) > 100
ORDER BY 
    total_profit DESC;
