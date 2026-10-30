
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS total_customers,
    SUM(ss_sales_price) AS total_sales,
    AVG(ss_net_profit) AS average_net_profit
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT c_customer_id) > 0
ORDER BY 
    total_sales DESC;
