
SELECT c.c_customer_id, 
       SUM(ws.ws_sales_price) AS total_sales, 
       COUNT(DISTINCT ws.ws_order_number) AS order_count, 
       MAX(ws.ws_sold_date_sk) AS last_purchase_date
FROM customer c
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE c.c_birth_year < 1980
GROUP BY c.c_customer_id
ORDER BY total_sales DESC
LIMIT 100;
