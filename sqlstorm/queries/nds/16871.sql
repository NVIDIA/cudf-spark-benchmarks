
SELECT c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state
FROM customer c
JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
WHERE a.ca_state = 'TX';
