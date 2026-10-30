
SELECT ca_state, COUNT(*) AS num_customers
FROM customer_address
JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
GROUP BY ca_state
ORDER BY num_customers DESC
LIMIT 10;
