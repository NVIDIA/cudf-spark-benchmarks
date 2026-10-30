
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS unique_customers, 
    SUM(ws_sales_price) AS total_sales 
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk 
JOIN 
    web_sales ON c_customer_sk = ws_bill_customer_sk 
GROUP BY 
    ca_state 
ORDER BY 
    total_sales DESC 
LIMIT 50;
