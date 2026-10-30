
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(ws_net_profit) AS total_net_profit,
    AVG(ws_net_paid) AS average_net_paid
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2022
GROUP BY 
    ca_city
ORDER BY 
    total_net_profit DESC
LIMIT 10;
