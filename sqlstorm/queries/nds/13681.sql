
SELECT ca_state, COUNT(DISTINCT c_customer_sk) AS customer_count, SUM(ss_net_profit) AS total_profit
FROM customer_address
JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN store_sales ON store_sales.ss_customer_sk = customer.c_customer_sk
JOIN date_dim ON date_dim.d_date_sk = store_sales.ss_sold_date_sk
WHERE date_dim.d_year = 2023
GROUP BY ca_state
ORDER BY total_profit DESC;
