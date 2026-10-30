
SELECT ca_county, COUNT(DISTINCT c_customer_sk) AS unique_customers, SUM(ss_net_profit) AS total_net_profit
FROM customer_address
JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN store_sales ON store_sales.ss_customer_sk = customer.c_customer_sk
GROUP BY ca_county
ORDER BY total_net_profit DESC
LIMIT 10;
