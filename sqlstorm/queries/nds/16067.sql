
SELECT ca_city, COUNT(*) AS num_customers
FROM customer
JOIN customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
GROUP BY ca_city
ORDER BY num_customers DESC
LIMIT 10;
