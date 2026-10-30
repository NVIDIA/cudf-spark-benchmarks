
SELECT ca_state, COUNT(ca_address_sk) AS address_count
FROM customer_address
GROUP BY ca_state
ORDER BY address_count DESC;
