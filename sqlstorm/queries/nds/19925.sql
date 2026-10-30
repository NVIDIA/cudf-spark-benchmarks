
SELECT ca_state, COUNT(*) AS customer_count
FROM customer AS c
JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY ca_state
ORDER BY customer_count DESC;
