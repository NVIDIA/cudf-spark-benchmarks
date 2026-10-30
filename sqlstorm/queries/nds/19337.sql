
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    d.d_date
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim AS d ON d.d_date_sk = c.c_first_shipto_date_sk
WHERE 
    ca.ca_state = 'CA'
ORDER BY 
    d.d_date DESC
LIMIT 100;
