
WITH  income_data AS (
    SELECT hd_demo_sk, hd_income_band_sk, 
           CASE 
               WHEN hd_income_band_sk < 1 THEN 'Unknown'
               WHEN hd_income_band_sk BETWEEN 1 AND 3 THEN 'Low'
               WHEN hd_income_band_sk BETWEEN 4 AND 6 THEN 'Medium'
               WHEN hd_income_band_sk > 6 THEN 'High' 
           END AS income_category
    FROM household_demographics
),
customer_with_addr AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           ca.ca_address_id, ca.ca_city,
           ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_first_name) AS city_rank
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT ws.ws_ship_date_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_profit,
           AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
    GROUP BY ws.ws_ship_date_sk
),
return_summary AS (
    SELECT cr.cr_item_sk,
           SUM(cr.cr_return_quantity) AS total_returns,
           COUNT(cr.cr_order_number) AS return_orders
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
final_output AS (
    SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name, id.income_category, 
           ss.total_quantity, ss.total_profit, ss.avg_net_paid,
           CASE 
               WHEN rs.return_orders IS NOT NULL THEN 'Returned'
               ELSE 'Not Returned'
           END AS return_status
    FROM customer_with_addr ci
    LEFT JOIN income_data id ON ci.c_customer_sk = id.hd_demo_sk
    LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_ship_date_sk
    LEFT JOIN return_summary rs ON ci.c_customer_sk = rs.cr_item_sk
    WHERE ci.city_rank = 1
)
SELECT *
FROM final_output
WHERE total_profit > 1000 OR (return_status = 'Returned' AND total_quantity < 5)
ORDER BY income_category, total_profit DESC;
