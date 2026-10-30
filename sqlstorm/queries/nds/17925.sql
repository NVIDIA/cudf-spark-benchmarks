
SELECT c_first_name, c_last_name, ca_city, ca_state, COUNT(sr_item_sk) AS total_returns
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY c_first_name, c_last_name, ca_city, ca_state
ORDER BY total_returns DESC
LIMIT 10;
