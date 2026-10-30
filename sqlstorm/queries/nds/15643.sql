
SELECT ca_state, COUNT(*) AS customer_count
FROM customer_address
JOIN customer ON customer.c_current_addr_sk = ca_address_sk
GROUP BY ca_state
ORDER BY customer_count DESC;
