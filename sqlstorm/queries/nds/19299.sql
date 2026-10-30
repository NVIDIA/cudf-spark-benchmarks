
SELECT ca_city, COUNT(*) AS customer_count
FROM customer_address
JOIN customer ON customer_address.ca_address_sk = customer.c_current_addr_sk
GROUP BY ca_city
ORDER BY customer_count DESC
LIMIT 10;
