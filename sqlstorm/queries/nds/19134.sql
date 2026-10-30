
SELECT c_first_name, c_last_name, ca_city, ca_state, SUM(ss_net_paid) AS total_sales
FROM customer
JOIN customer_address ON c_current_addr_sk = ca_address_sk
JOIN store_sales ON c_customer_sk = ss_customer_sk
GROUP BY c_first_name, c_last_name, ca_city, ca_state
ORDER BY total_sales DESC
LIMIT 10;
