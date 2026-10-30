
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ss_quantity) AS total_sales,
    AVG(ss_net_profit) AS average_profit
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;
