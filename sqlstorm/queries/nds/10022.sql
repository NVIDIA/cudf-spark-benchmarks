
SELECT COUNT(*) AS total_sales, 
       SUM(ws_ext_sales_price) AS total_revenue, 
       AVG(ws_quantity) AS avg_quantity_per_sale 
FROM web_sales 
WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450500 
  AND ws_ship_mode_sk IN (SELECT sm_ship_mode_sk 
                          FROM ship_mode 
                          WHERE sm_type = 'Standard')
GROUP BY ws_ship_mode_sk 
ORDER BY total_revenue DESC;
