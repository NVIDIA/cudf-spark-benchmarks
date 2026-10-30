
SELECT SUM(ws_sales_price) AS total_sales, COUNT(ws_order_number) AS total_orders
FROM web_sales
WHERE ws_sold_date_sk BETWEEN 1 AND 100
GROUP BY ws_web_site_sk
ORDER BY total_sales DESC;
