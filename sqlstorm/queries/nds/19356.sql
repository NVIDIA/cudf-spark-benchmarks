
SELECT c.c_customer_id, COUNT(ws.ws_order_number) AS total_orders, SUM(ws.ws_sales_price) AS total_sales
FROM customer c
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY c.c_customer_id
HAVING SUM(ws.ws_sales_price) > 1000
ORDER BY total_sales DESC;
