
SELECT ca_city, COUNT(c_customer_sk) AS total_customers
FROM customer AS c
JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY ca_city
ORDER BY total_customers DESC
LIMIT 10;
