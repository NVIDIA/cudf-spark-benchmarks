
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ws.ws_net_paid) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid) AS average_order_value,
    MAX(ws.ws_net_paid) AS highest_order_value,
    MIN(ws.ws_net_paid) AS lowest_order_value,
    d.d_year,
    d.d_month_seq,
    a.ca_state
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
    AND a.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    d.d_year,
    d.d_month_seq,
    a.ca_state
HAVING 
    SUM(ws.ws_net_paid) > 1000
ORDER BY 
    total_spent DESC, 
    c.c_last_name, 
    c.c_first_name;
