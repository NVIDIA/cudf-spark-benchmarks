
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city
ORDER BY 
    total_net_profit DESC
LIMIT 10;
