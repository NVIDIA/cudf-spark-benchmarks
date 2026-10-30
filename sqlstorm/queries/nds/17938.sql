
SELECT c.c_customer_id, SUM(ws.ws_net_paid) AS total_sales
FROM customer c
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY c.c_customer_id
ORDER BY total_sales DESC
LIMIT 10;
