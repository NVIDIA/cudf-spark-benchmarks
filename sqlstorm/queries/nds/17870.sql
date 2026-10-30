
SELECT ca_city, COUNT(c_customer_sk) AS customer_count
FROM customer
JOIN customer_address ON c_current_addr_sk = ca_address_sk
GROUP BY ca_city
ORDER BY customer_count DESC
LIMIT 10;
