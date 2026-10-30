
SELECT ca_city, COUNT(*) AS number_of_addresses 
FROM customer_address 
GROUP BY ca_city 
ORDER BY number_of_addresses DESC 
LIMIT 10;
