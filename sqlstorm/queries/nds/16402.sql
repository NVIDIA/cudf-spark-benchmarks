
SELECT ca_city, COUNT(*) AS num_customers
FROM customer_address
JOIN customer ON ca_address_sk = c_current_addr_sk
GROUP BY ca_city
ORDER BY num_customers DESC
LIMIT 10;
