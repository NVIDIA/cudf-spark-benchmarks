
SELECT c.c_customer_id,
       COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
       SUM(ws.ws_net_profit) AS total_web_profit
FROM customer c
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY c.c_customer_id
ORDER BY total_web_profit DESC
LIMIT 100;
