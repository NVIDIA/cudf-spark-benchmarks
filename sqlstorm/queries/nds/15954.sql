
SELECT ca_city, COUNT(*) AS city_count 
FROM customer_address 
GROUP BY ca_city 
ORDER BY city_count DESC 
LIMIT 10;
