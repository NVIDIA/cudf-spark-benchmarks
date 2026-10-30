
SELECT ca_city, COUNT(DISTINCT c_customer_id) AS num_customers
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY ca_city
ORDER BY num_customers DESC
LIMIT 10;
