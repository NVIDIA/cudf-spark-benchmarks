
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_profit) AS average_profit,
    COUNT(DISTINCT CASE WHEN p.p_promo_id IS NOT NULL THEN ws.ws_order_number END) AS promo_orders,
    d.d_year
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2022
    AND ca.ca_state = 'CA'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, d.d_year
ORDER BY 
    total_sales DESC, c.c_last_name ASC
LIMIT 100;
