
SELECT c_first_name, c_last_name, ca_city, ca_state
FROM customer
JOIN customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
WHERE ca_city = 'San Francisco'
ORDER BY c_last_name, c_first_name;
