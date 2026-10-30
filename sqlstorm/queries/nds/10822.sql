
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS num_customers,
    SUM(ss_net_profit) AS total_net_profit
FROM 
    customer_address CA
JOIN 
    customer C ON CA.ca_address_sk = C.c_current_addr_sk
JOIN 
    store_sales SS ON C.c_customer_sk = SS.ss_customer_sk
WHERE 
    CA.ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca_state
ORDER BY 
    total_net_profit DESC
LIMIT 10;
