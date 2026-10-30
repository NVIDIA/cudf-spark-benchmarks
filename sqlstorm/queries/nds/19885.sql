
SELECT ca_city, COUNT(*) AS customer_count
FROM customer_address
JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
GROUP BY ca_city
HAVING COUNT(*) > 10
ORDER BY customer_count DESC;
