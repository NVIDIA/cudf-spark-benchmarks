
SELECT ca_city, COUNT(*) as number_of_customers 
FROM customer_address 
GROUP BY ca_city 
ORDER BY number_of_customers DESC 
LIMIT 10;
