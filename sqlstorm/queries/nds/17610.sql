
SELECT ca_country, COUNT(*) AS customer_count
FROM customer_address
JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
GROUP BY ca_country
ORDER BY customer_count DESC;
