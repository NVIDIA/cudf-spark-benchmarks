
SELECT c_first_name, c_last_name, ca_city
FROM customer
JOIN customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
WHERE ca_state = 'CA';
