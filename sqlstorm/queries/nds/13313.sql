
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    SUM(COALESCE(ws_sales_price, 0)) AS total_sales
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ca_city
HAVING 
    COUNT(DISTINCT c_customer_sk) > 100
ORDER BY 
    total_sales DESC
LIMIT 10;
