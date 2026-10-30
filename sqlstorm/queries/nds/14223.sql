
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    COUNT(o.ss_ticket_number) AS total_sales,
    SUM(o.ss_net_profit) AS total_profit
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales o ON c.c_customer_sk = o.ss_customer_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    c.c_customer_id, ca.ca_city, ca.ca_state
ORDER BY 
    total_profit DESC
LIMIT 100;
