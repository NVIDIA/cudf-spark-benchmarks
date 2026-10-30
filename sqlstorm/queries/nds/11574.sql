
SELECT ca_state, COUNT(DISTINCT c_customer_id) AS customer_count, SUM(ws_ext_sales_price) AS total_sales
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
GROUP BY ca_state
ORDER BY customer_count DESC
LIMIT 10;
