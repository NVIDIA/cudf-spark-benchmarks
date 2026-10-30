
SELECT ca_city, COUNT(*) AS address_count 
FROM customer_address 
GROUP BY ca_city 
ORDER BY address_count DESC 
LIMIT 10;
