
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(cs.cs_net_profit) AS total_catalog_profit
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
WHERE 
    ca.ca_city LIKE 'San%' 
    AND ca.ca_state = 'CA' 
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 10
    AND COUNT(DISTINCT cs.cs_order_number) > 5
ORDER BY 
    total_web_profit DESC, total_catalog_profit DESC
LIMIT 10;
