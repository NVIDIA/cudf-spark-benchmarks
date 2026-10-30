
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_id) AS unique_customers, 
    SUM(ws_net_profit) AS total_profit
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca_state = 'CA' AND 
    ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
GROUP BY 
    ca_city
ORDER BY 
    total_profit DESC
LIMIT 10;
