
SELECT ca_city, COUNT(DISTINCT c_customer_sk) AS unique_customers
FROM customer_address
JOIN customer ON customer.c_current_addr_sk = ca_address_sk
GROUP BY ca_city
ORDER BY unique_customers DESC
LIMIT 10;
