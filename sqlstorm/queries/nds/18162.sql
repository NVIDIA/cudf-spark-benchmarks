
SELECT CA.ca_city, COUNT(CA.ca_address_sk) AS address_count
FROM customer_address CA
GROUP BY CA.ca_city
ORDER BY address_count DESC
LIMIT 10;
