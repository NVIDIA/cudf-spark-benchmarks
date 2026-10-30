
SELECT c_first_name, c_last_name, ca_city, ca_state, SUM(ss_sales_price) AS total_sales
FROM customer AS c
JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY c.c_customer_sk, c_first_name, c_last_name, ca_city, ca_state
ORDER BY total_sales DESC
LIMIT 10;
