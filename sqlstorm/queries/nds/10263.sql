
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_net_profit) AS average_profit
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk 
JOIN 
    store_sales ON c_customer_sk = ss_customer_sk 
GROUP BY 
    ca_state 
HAVING 
    COUNT(DISTINCT c_customer_sk) > 1000 
ORDER BY 
    total_sales DESC;
