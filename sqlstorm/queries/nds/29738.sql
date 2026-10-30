
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(LENGTH(c.c_first_name) + LENGTH(c.c_last_name)) AS avg_name_length,
    MAX(ws.ws_net_paid_inc_tax) AS max_net_paid,
    MIN(ws.ws_net_paid_inc_ship_tax) AS min_net_paid_ship_tax
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'TX', 'NY')
    AND c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    unique_customers DESC, total_net_profit DESC
LIMIT 100;
