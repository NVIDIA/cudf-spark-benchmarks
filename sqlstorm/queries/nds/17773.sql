
SELECT ca_city, COUNT(*) as total_customers
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY ca_city
ORDER BY total_customers DESC
LIMIT 10;
