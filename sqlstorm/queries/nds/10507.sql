
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT cr.cr_order_number) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
WHERE 
    ca.ca_state = 'CA' AND 
    cr.cr_returned_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
GROUP BY 
    c.c_customer_id, ca.ca_city, ca.ca_state
ORDER BY 
    total_returns DESC
LIMIT 10;
