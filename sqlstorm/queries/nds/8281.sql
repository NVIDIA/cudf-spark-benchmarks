
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_net_paid_inc_tax) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
    AND c.c_birth_year >= 1950
    AND ca.ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    c.c_customer_id, ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_net_paid_inc_tax) > 500
ORDER BY 
    total_spent DESC
LIMIT 100;
