
SELECT ca_city, COUNT(*) AS total_addresses
FROM customer_address
GROUP BY ca_city
ORDER BY total_addresses DESC
LIMIT 10;
