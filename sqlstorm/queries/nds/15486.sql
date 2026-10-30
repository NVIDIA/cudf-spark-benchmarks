
SELECT ca_state, COUNT(*) AS total_addresses
FROM customer_address
GROUP BY ca_state
ORDER BY total_addresses DESC
LIMIT 10;
