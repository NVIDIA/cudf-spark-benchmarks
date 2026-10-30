
SELECT c.c_customer_id, SUM(ss.ss_net_paid) AS total_spent
FROM customer AS c
JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY c.c_customer_id
ORDER BY total_spent DESC
LIMIT 10;
