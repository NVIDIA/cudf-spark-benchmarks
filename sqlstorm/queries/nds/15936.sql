
SELECT c_first_name, c_last_name, SUM(ss_net_paid) AS total_sales
FROM customer
JOIN store_sales ON customer.c_customer_sk = store_sales.ss_customer_sk
GROUP BY c_first_name, c_last_name
ORDER BY total_sales DESC
LIMIT 10;
