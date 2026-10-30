
SELECT ca_country, COUNT(*) AS customer_count
FROM customer_address
GROUP BY ca_country
ORDER BY customer_count DESC
LIMIT 10;
