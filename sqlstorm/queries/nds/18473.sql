
SELECT c.c_customer_id, ca.ca_city, ca.ca_state, COUNT(*) AS total_purchases
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY c.c_customer_id, ca.ca_city, ca.ca_state
ORDER BY total_purchases DESC
LIMIT 10;
