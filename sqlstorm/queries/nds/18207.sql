
SELECT ca_city, COUNT(DISTINCT c_customer_sk) AS customer_count
FROM customer_address
JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
GROUP BY ca_city
HAVING COUNT(DISTINCT c_customer_sk) > 10
ORDER BY customer_count DESC;
