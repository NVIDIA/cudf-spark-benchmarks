
SELECT c.c_first_name, c.c_last_name, SUM(s.ss_sales_price) AS total_sales
FROM customer c
JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
GROUP BY c.c_first_name, c.c_last_name
ORDER BY total_sales DESC
LIMIT 10;
