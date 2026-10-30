
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    COUNT(DISTINCT CASE WHEN ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231 THEN ws.ws_order_number END) AS total_orders_2021,
    SUM(CASE WHEN ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231 THEN ws.ws_net_paid ELSE 0 END) AS total_spent_2021,
    SUM(CASE WHEN ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231 THEN ws.ws_net_paid ELSE 0 END) / NULLIF(COUNT(DISTINCT CASE WHEN ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231 THEN ws.ws_order_number END), 0) AS avg_spent_per_order_2021
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    c.c_birth_year < 1980 AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
ORDER BY 
    total_spent DESC
LIMIT 100;
