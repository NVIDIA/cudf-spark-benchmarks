
SELECT ca_city, COUNT(DISTINCT c_customer_id) AS number_of_customers
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY ca_city
ORDER BY number_of_customers DESC
LIMIT 10;
