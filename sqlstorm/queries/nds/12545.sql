
SELECT SUM(ws_ext_sales_price) AS total_sales, COUNT(DISTINCT ws_order_number) AS total_orders
FROM web_sales
WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451546
GROUP BY ws_web_site_sk
ORDER BY total_sales DESC;
