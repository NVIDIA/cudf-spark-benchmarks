
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    SUM(ss_sales_price) AS total_sales,
    AVG(ss_net_profit) AS avg_net_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
WHERE 
    ca_state IS NOT NULL
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;
