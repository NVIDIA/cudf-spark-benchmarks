
SELECT ca_city, COUNT(*) AS customer_count
FROM customer_address
INNER JOIN customer ON customer.c_current_addr_sk = ca_address_sk
GROUP BY ca_city
ORDER BY customer_count DESC
LIMIT 10;
