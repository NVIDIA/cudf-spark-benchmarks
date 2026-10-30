
SELECT ca_city, COUNT(*) as total_addresses
FROM customer_address
GROUP BY ca_city
ORDER BY total_addresses DESC
LIMIT 10;
