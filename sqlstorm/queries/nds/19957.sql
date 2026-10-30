
SELECT ca_street_name, ca_city, ca_state, COUNT(*) AS customer_count
FROM customer_address
JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
GROUP BY ca_street_name, ca_city, ca_state
ORDER BY customer_count DESC
LIMIT 10;
