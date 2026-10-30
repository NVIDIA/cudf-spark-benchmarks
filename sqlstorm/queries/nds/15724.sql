
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_net_profit) AS total_profit
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_profit DESC
LIMIT 10;
