
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_id) AS customer_count, 
    SUM(ss_net_profit) AS total_net_profit
FROM 
    customer_address
JOIN 
    customer ON ca_address_sk = c_current_addr_sk
JOIN 
    store_sales ON c_customer_sk = ss_customer_sk
WHERE 
    ca_state IS NOT NULL
GROUP BY 
    ca_state
ORDER BY 
    total_net_profit DESC
LIMIT 10;
