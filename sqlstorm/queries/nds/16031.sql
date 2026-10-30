
SELECT ca_city, COUNT(*) as customer_count
FROM customer_address
JOIN customer ON ca_address_sk = c_current_addr_sk
GROUP BY ca_city
ORDER BY customer_count DESC
LIMIT 10;
