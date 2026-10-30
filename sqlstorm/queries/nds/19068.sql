
SELECT ca_city, COUNT(*) AS customer_count
FROM customer_address
WHERE ca_state = 'CA'
GROUP BY ca_city
ORDER BY customer_count DESC
LIMIT 10;
