
SELECT 
    c_first_name, 
    c_last_name, 
    ca_city, 
    ca_state 
FROM 
    customer 
JOIN 
    customer_address ON c_current_addr_sk = ca_address_sk 
WHERE 
    ca_city = 'San Francisco' 
    AND ca_state = 'CA';
