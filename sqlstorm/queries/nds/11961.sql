
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS customer_count, 
    SUM(ss_sales_price) AS total_sales, 
    AVG(ws_net_profit) AS average_web_profit 
FROM 
    customer_address ca 
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk 
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk 
GROUP BY 
    ca_state 
ORDER BY 
    total_sales DESC 
LIMIT 10;
