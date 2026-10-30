
SELECT c_first_name, c_last_name, ca_city, ca_state, SUM(ss_net_profit) as total_profit
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY c_first_name, c_last_name, ca_city, ca_state
ORDER BY total_profit DESC
LIMIT 10;
