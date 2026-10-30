
SELECT c_first_name, c_last_name, SUM(ws_net_profit) AS total_net_profit
FROM customer
JOIN web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
WHERE c_current_cdemo_sk IS NOT NULL
AND ws_sold_date_sk BETWEEN 1000 AND 2000
GROUP BY c_first_name, c_last_name
ORDER BY total_net_profit DESC
LIMIT 10;
