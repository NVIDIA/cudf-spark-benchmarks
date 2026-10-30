
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS total_customers,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    web_sales ws
JOIN 
    customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    dd.d_year = 2023 
    AND p.p_discount_active = 'Y'
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_quantity) > 1000
ORDER BY 
    avg_net_profit DESC
LIMIT 10;
