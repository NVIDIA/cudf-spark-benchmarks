
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT c.c_customer_id) AS customer_count, 
    SUM(ws.ws_net_paid) AS total_sales, 
    AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid_inc_tax
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 AND 
    d.d_moy IN (11, 12) 
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 100 
ORDER BY 
    total_sales DESC 
LIMIT 10;
