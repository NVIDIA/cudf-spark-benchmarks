
SELECT ca_state, COUNT(*) as address_count
FROM customer_address
GROUP BY ca_state
ORDER BY address_count DESC
LIMIT 10;
