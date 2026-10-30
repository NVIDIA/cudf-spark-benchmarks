
SELECT ca_city, COUNT(*)
FROM customer_address
GROUP BY ca_city
ORDER BY COUNT(*) DESC
LIMIT 10;
