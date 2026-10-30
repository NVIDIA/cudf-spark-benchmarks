
SELECT c.c_customer_id, SUM(ss.ss_net_profit) AS total_net_profit
FROM customer c
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE ss.ss_sold_date_sk BETWEEN 20230101 AND 20231231
GROUP BY c.c_customer_id
ORDER BY total_net_profit DESC
LIMIT 10;
