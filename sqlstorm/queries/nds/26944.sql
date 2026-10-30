
SELECT 
    SUBSTRING(c.c_first_name, 1, 1) AS first_initial,
    c.c_last_name AS last_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    AVG(ws.ws_sales_price) AS avg_order_value,
    MAX(ws.ws_sales_price) AS max_order_value,
    MIN(ws.ws_sales_price) AS min_order_value
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
    AND ca.ca_state IN ('CA', 'NY', 'TX')
    AND ws.ws_sold_date_sk IN (
        SELECT DISTINCT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq IN (1, 2, 3)
    )
GROUP BY 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC, 
    last_name ASC;
