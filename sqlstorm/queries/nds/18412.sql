
SELECT ca_state, COUNT(DISTINCT c_customer_sk) AS num_customers
FROM customer_address
JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
GROUP BY ca_state
ORDER BY num_customers DESC;
