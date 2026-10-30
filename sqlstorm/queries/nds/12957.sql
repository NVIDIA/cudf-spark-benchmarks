
SELECT ca_state, COUNT(DISTINCT c_customer_sk) AS num_customers
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY ca_state
ORDER BY num_customers DESC;
