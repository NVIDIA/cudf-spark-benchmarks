
SELECT c_first_name, c_last_name, SUM(ws_net_profit) AS total_profit
FROM customer
JOIN web_sales ON c_customer_sk = ws_bill_customer_sk
JOIN date_dim ON ws_sold_date_sk = d_date_sk
WHERE d_year = 2022
GROUP BY c_first_name, c_last_name
ORDER BY total_profit DESC
LIMIT 10;
