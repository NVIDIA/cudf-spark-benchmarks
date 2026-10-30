
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(ss_net_paid) AS total_sales,
    AVG(ws_net_profit) AS avg_web_sales_profit
FROM 
    customer_address
JOIN 
    customer ON ca_address_sk = c_current_addr_sk
JOIN 
    store_sales ON c_customer_sk = ss_customer_sk
JOIN 
    web_sales ON c_customer_sk = ws_bill_customer_sk
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;
