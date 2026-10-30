
SELECT COUNT(*) AS total_sales, SUM(ws_ext_sales_price) AS total_revenue
FROM web_sales
WHERE ws_sold_date_sk BETWEEN 1 AND 1000
GROUP BY ws_ship_mode_sk
ORDER BY total_revenue DESC;
