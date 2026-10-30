
SELECT c.c_customer_id, ca.ca_city, ca.ca_state, COUNT(sr.sr_ticket_number) AS total_returns
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY c.c_customer_id, ca.ca_city, ca.ca_state
ORDER BY total_returns DESC
LIMIT 10;
