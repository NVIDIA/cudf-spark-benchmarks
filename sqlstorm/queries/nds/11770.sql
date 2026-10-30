
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(ws_sales_price) AS total_sales,
    AVG(ws_net_profit) AS average_net_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN 1000 AND 1500
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;
