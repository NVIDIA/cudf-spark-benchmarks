
SELECT ca_city, COUNT(*) AS customer_count
FROM customer
JOIN customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
GROUP BY ca_city
ORDER BY customer_count DESC
LIMIT 10;
