
SELECT ca_state, COUNT(DISTINCT c_customer_id) AS unique_customers, SUM(ss_net_profit) AS total_profit
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY ca_state
ORDER BY total_profit DESC
LIMIT 10;
