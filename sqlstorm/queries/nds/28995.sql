
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_city, 
    ca.ca_state,
    SUM(ws.ws_net_paid) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    CASE 
        WHEN COUNT(DISTINCT ws.ws_order_number) = 0 THEN 'No Orders'
        WHEN SUM(ws.ws_net_paid) < 100 THEN 'Low Spender'
        WHEN SUM(ws.ws_net_paid) BETWEEN 100 AND 500 THEN 'Medium Spender'
        WHEN SUM(ws.ws_net_paid) > 500 THEN 'High Spender'
        ELSE 'Unknown'
    END AS spender_category
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_city LIKE '%City%' 
    AND ca.ca_state IN ('CA', 'NY', 'TX')
    AND ws.ws_sold_date_sk > (
        SELECT MAX(d.d_date_sk) 
        FROM date_dim d 
        WHERE d.d_year = 2022
    )
GROUP BY 
    customer_name, 
    ca.ca_city, 
    ca.ca_state
ORDER BY 
    total_spent DESC
LIMIT 10;
