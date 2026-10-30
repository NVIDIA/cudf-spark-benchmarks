
SELECT c_first_name, c_last_name, SUM(ss_sales_price) AS total_sales
FROM customer
JOIN store_sales ON c_customer_sk = ss_customer_sk
GROUP BY c_first_name, c_last_name
ORDER BY total_sales DESC
LIMIT 10;
