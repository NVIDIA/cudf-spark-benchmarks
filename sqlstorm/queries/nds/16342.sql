
SELECT SUM(ws_net_profit) AS total_net_profit
FROM web_sales
WHERE ws_sold_date_sk BETWEEN 1 AND 1000;
