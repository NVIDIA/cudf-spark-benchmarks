
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
    LENGTH(ca.ca_street_name) AS street_name_length, 
    SUBSTRING(ca.ca_street_name, 1, POSITION(' ' IN ca.ca_street_name || ' ') - 1) AS first_word_street_name 
FROM 
    customer AS c 
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk 
WHERE 
    ca.ca_city LIKE '%York%' 
    AND (c.c_first_name LIKE 'A%' OR c.c_last_name LIKE 'A%') 
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    ca.ca_street_name 
ORDER BY 
    street_name_length DESC 
LIMIT 100;
