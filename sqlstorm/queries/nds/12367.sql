
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    SUM(COALESCE(ws_net_profit, 0)) AS total_net_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ca_state
ORDER BY 
    total_net_profit DESC
LIMIT 10;
