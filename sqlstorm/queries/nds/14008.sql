
SELECT c.c_first_name, c.c_last_name, SUM(ss.ss_sales_price) AS total_sales
FROM customer c
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE s.s_city = 'San Francisco'
AND ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231
GROUP BY c.c_first_name, c.c_last_name
ORDER BY total_sales DESC
LIMIT 10;
