
SELECT c_first_name, c_last_name, ca_city, ca_state
FROM customer
JOIN customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
WHERE ca_state = 'CA' AND c_customer_sk < 1000
ORDER BY c_last_name, c_first_name;
