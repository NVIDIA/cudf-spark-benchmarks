
SELECT ca_state, COUNT(DISTINCT c_customer_id) AS unique_customers, SUM(ss_net_profit) AS total_profit
FROM customer_address
JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN store_sales ON store_sales.ss_customer_sk = customer.c_customer_sk
WHERE ca_state IS NOT NULL
GROUP BY ca_state
ORDER BY total_profit DESC
LIMIT 10;
