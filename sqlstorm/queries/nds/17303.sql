
SELECT ca_state, COUNT(*) AS num_customers
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY ca_state
ORDER BY num_customers DESC
LIMIT 10;
