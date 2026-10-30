
SELECT c_first_name, c_last_name, ca_city, ca_state 
FROM customer AS c 
JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk 
WHERE ca_state = 'CA' 
ORDER BY c_last_name;
