
SELECT s_store_name, SUM(ss_net_profit) AS total_net_profit
FROM store_sales
JOIN store ON store.s_store_sk = store_sales.ss_store_sk
GROUP BY s_store_name
ORDER BY total_net_profit DESC
LIMIT 10;
