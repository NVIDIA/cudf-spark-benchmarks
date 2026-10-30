
SELECT ca_city, COUNT(*) AS customers
FROM customer_address
GROUP BY ca_city
ORDER BY customers DESC
LIMIT 10;
