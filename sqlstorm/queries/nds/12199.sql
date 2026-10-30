
SELECT 
    ca_state, 
    SUM(ws_net_profit) AS total_net_profit, 
    COUNT(DISTINCT c_customer_sk) AS unique_customers
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
GROUP BY 
    ca_state
ORDER BY 
    total_net_profit DESC
LIMIT 10;
