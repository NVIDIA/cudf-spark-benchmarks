
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    d.d_date AS purchase_date,
    SUM(ws.ws_ext_sales_price) AS total_spent
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
AND 
    (LOWER(c.c_first_name) LIKE '%a%' OR LOWER(c.c_last_name) LIKE '%a%')
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, d.d_date
HAVING 
    SUM(ws.ws_ext_sales_price) > 100
ORDER BY 
    total_spent DESC
LIMIT 10;
