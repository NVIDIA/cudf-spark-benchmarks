
SELECT 
    ca_address_id, 
    ca_city, 
    ca_state 
FROM 
    customer_address 
WHERE 
    ca_state = 'CA' 
ORDER BY 
    ca_city;
