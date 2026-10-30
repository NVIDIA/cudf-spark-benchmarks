
SELECT ca_city, COUNT(c_customer_sk) AS total_customers
FROM customer_address
JOIN customer ON ca_address_sk = c_current_addr_sk
GROUP BY ca_city
ORDER BY total_customers DESC
LIMIT 10;
