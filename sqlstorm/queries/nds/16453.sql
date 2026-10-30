
SELECT ca_state, COUNT(*) AS total_customers
FROM customer_address
GROUP BY ca_state
ORDER BY total_customers DESC
LIMIT 10;
