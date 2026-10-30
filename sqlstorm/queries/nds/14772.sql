
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_id) AS customer_count, 
    SUM(ss_quantity) AS total_quantity_sold, 
    AVG(ws_net_profit) AS avg_net_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ca_state
ORDER BY 
    customer_count DESC
LIMIT 100;
