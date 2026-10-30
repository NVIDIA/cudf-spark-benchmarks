
SELECT c.c_customer_id, 
       SUM(ws.ws_sales_price) AS total_sales, 
       COUNT(ws.ws_order_number) AS total_orders 
FROM customer c 
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
WHERE c.c_current_cdemo_sk IS NOT NULL 
GROUP BY c.c_customer_id 
ORDER BY total_sales DESC 
LIMIT 100;
