
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    MAX(ws.ws_sold_date_sk) AS last_order_date,
    CASE 
        WHEN MAX(ws.ws_sales_price) > 100 THEN 'High Value Customer'
        WHEN MAX(ws.ws_sales_price) BETWEEN 50 AND 100 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX')
    AND c.c_birth_month BETWEEN 1 AND 12
    AND c.c_birth_year IS NOT NULL
GROUP BY 
    c.c_customer_sk, full_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 0
ORDER BY 
    total_spent DESC, last_order_date DESC
LIMIT 100;
