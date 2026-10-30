
SELECT c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'CA'
ORDER BY c.c_last_name;
