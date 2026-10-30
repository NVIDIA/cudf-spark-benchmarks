
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
    d.d_date AS transaction_date,
    SUM(ws.ws_sales_price) AS total_spent,
    CASE 
        WHEN SUM(ws.ws_sales_price) > 1000 THEN 'High Value Customer'
        WHEN SUM(ws.ws_sales_price) BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
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
    AND c.c_email_address LIKE '%@example.com'
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_street_number, 
    ca.ca_street_name, 
    ca.ca_street_type, 
    d.d_date
ORDER BY 
    total_spent DESC
LIMIT 50;
