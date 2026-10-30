
SELECT c_first_name, c_last_name, SUM(ss_net_paid) AS total_spent
FROM customer
JOIN store_sales ON c_customer_sk = ss_customer_sk
GROUP BY c_first_name, c_last_name
ORDER BY total_spent DESC
LIMIT 10;
