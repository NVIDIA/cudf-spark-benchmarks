
SELECT 
    UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name,
    ca.ca_city,
    ca.ca_state,
    d.d_date AS last_purchase_date,
    COUNT(*) AS purchase_count,
    SUM(ws.ws_net_paid) AS total_spent
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_year BETWEEN 1970 AND 1990
    AND ca.ca_country = 'USA'
    AND d.d_year = 2023
GROUP BY 
    full_name, ca.ca_city, ca.ca_state, last_purchase_date
HAVING 
    COUNT(*) > 5
ORDER BY 
    total_spent DESC
LIMIT 50;
