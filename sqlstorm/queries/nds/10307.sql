SELECT ca_state, COUNT(DISTINCT c_customer_id) AS customer_count
FROM customer_address
JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
WHERE ca_state IN ('CA', 'TX', 'NY')
GROUP BY ca_state
ORDER BY customer_count DESC;