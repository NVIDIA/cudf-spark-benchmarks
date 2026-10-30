
SELECT 
    ca_country, 
    COUNT(DISTINCT c_customer_sk) AS customer_count, 
    SUM(ss_net_paid) AS total_sales, 
    SUM(ws_net_profit) AS total_web_sales
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ca_country
ORDER BY 
    total_sales DESC
LIMIT 100;
