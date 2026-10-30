
SELECT ca_state, COUNT(DISTINCT c_customer_sk) AS customer_count
FROM customer_address
JOIN customer ON ca_address_sk = c_current_addr_sk
GROUP BY ca_state
ORDER BY customer_count DESC;
