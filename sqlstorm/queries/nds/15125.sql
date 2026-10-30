
SELECT ca_city, COUNT(*) AS num_customers
FROM customer_address
GROUP BY ca_city
ORDER BY num_customers DESC
LIMIT 10;
