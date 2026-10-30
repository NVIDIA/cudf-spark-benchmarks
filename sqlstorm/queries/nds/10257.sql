
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS total_customers,
    COUNT(DISTINCT s_store_sk) AS total_stores,
    SUM(ws_net_profit) AS total_net_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    store s ON c.c_customer_sk = s.s_store_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ca_state
ORDER BY 
    total_net_profit DESC
LIMIT 10;
