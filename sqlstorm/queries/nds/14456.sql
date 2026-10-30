
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    SUM(ws_sales_price) AS total_sales,
    AVG(ws_net_profit) AS average_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca_state = 'CA' AND 
    ws_sold_date_sk BETWEEN 1 AND 1000
GROUP BY 
    ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
