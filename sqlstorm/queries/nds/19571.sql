
SELECT ca_city, COUNT(*) as total_customers
FROM customer_address
JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
GROUP BY ca_city
ORDER BY total_customers DESC
LIMIT 10;
