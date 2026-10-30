
SELECT ca_city, COUNT(*) AS num_addresses
FROM customer_address
GROUP BY ca_city
ORDER BY num_addresses DESC
LIMIT 10;
