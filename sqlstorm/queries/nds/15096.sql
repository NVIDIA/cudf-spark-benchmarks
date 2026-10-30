
SELECT c_customer_id, SUM(ss_sales_price) AS total_sales
FROM customer
JOIN store_sales ON c_customer_sk = ss_customer_sk
GROUP BY c_customer_id
ORDER BY total_sales DESC
LIMIT 10;
