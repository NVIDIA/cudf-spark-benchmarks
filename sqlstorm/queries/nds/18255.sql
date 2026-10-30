
SELECT ca_city, COUNT(*) as total_customers
FROM customer_address
GROUP BY ca_city
ORDER BY total_customers DESC
LIMIT 10;
