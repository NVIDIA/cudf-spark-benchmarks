
SELECT c.c_first_name, c.c_last_name, ca.ca_city, COUNT(sr.sr_item_sk) AS return_count
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY c.c_first_name, c.c_last_name, ca.ca_city
ORDER BY return_count DESC
LIMIT 10;
