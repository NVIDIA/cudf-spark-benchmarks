
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    SUM(ss_net_paid) AS total_sales
FROM 
    customer_address 
JOIN 
    customer ON c_current_addr_sk = ca_address_sk
JOIN 
    store_sales ON ss_customer_sk = c_customer_sk
WHERE 
    ca_state IS NOT NULL
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;
