
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_online_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders,
    SUM(ws.ws_net_profit) AS total_online_profit,
    SUM(ss.ss_net_profit) AS total_store_profit,
    CASE 
        WHEN COUNT(DISTINCT ws.ws_order_number) > COUNT(DISTINCT ss.ss_ticket_number) THEN 'Online'
        WHEN COUNT(DISTINCT ss.ss_ticket_number) > COUNT(DISTINCT ws.ws_order_number) THEN 'Store'
        ELSE 'Equal'
    END AS preferred_channel
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'TX', 'NY') 
    AND c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
ORDER BY 
    total_online_profit DESC, total_store_profit DESC
LIMIT 100;
