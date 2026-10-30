
SELECT a.ca_city, COUNT(c.c_customer_sk) AS customer_count
FROM customer_address a
JOIN customer c ON a.ca_address_sk = c.c_current_addr_sk
GROUP BY a.ca_city
ORDER BY customer_count DESC
LIMIT 10;
