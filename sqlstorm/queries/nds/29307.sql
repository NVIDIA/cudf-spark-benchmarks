
SELECT 
    ca.ca_city, 
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(LENGTH(c.c_first_name) + LENGTH(c.c_last_name)) AS avg_name_length,
    MAX(p.p_discount_active) AS max_discount_status
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    promotion AS p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND ca.ca_state IS NOT NULL 
    AND p.p_discount_active = 'Y'
GROUP BY 
    ca.ca_city, 
    ca.ca_state
ORDER BY 
    total_net_profit DESC, 
    unique_customers DESC
LIMIT 50;
