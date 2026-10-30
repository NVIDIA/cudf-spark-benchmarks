
SELECT c.c_first_name, c.c_last_name, SUM(ss.ss_quantity) AS total_quantity
FROM customer c
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY c.c_first_name, c.c_last_name
ORDER BY total_quantity DESC
LIMIT 10;
