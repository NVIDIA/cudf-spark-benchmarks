
SELECT ca_state, COUNT(DISTINCT c_customer_id) AS unique_customers, SUM(ss_sales_price) AS total_sales
FROM customer_address
JOIN customer ON ca_address_sk = c_current_addr_sk
JOIN store_sales ON c_customer_sk = ss_customer_sk
GROUP BY ca_state
ORDER BY total_sales DESC
LIMIT 10;
