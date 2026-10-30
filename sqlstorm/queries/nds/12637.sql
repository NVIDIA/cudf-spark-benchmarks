
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_sk) AS customer_count, 
    SUM(ws_net_paid) AS total_sales
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk 
JOIN 
    web_sales ON c_customer_sk = ws_bill_customer_sk 
GROUP BY 
    ca_city 
ORDER BY 
    total_sales DESC 
LIMIT 10;
