
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA'
    AND ws.ws_sold_date_sk BETWEEN 2458849 AND 2458949
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_net_profit DESC
LIMIT 100;
