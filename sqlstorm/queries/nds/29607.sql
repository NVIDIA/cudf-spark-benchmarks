
SELECT 
    c.c_first_name AS first_name, 
    c.c_last_name AS last_name, 
    a.ca_city AS city, 
    a.ca_state AS state, 
    d.d_date AS transaction_date, 
    SUM(ws.ws_net_profit) AS total_profit
FROM 
    customer c
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_year >= 1980 AND 
    c.c_birth_year <= 2000
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    a.ca_city, 
    a.ca_state, 
    d.d_date
HAVING 
    SUM(ws.ws_net_profit) > 1000
ORDER BY 
    total_profit DESC
LIMIT 10;
