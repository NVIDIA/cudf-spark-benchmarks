
SELECT c.c_customer_id, 
       SUM(ws.ws_sales_price) AS total_sales,
       COUNT(DISTINCT ws.ws_order_number) AS order_count,
       AVG(ws.ws_sales_price) AS average_order_value
FROM customer c
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE c.c_birth_year BETWEEN 1960 AND 1980
GROUP BY c.c_customer_id
ORDER BY total_sales DESC
LIMIT 100;
