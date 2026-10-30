
SELECT ca_state, COUNT(c_customer_sk) AS customer_count, SUM(ss_net_profit) AS total_profit
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE ss.ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY ca_state
ORDER BY total_profit DESC
LIMIT 10;
