
SELECT ca_city, COUNT(c_customer_sk) AS customer_count
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY ca_city
ORDER BY customer_count DESC
LIMIT 10;
