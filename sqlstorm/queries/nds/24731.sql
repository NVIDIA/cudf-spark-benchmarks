
WITH  income_ranges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound,
           CASE 
               WHEN ib_lower_bound IS NULL OR ib_upper_bound IS NULL THEN 'UNKNOWN'
               WHEN ib_lower_bound < 0 THEN 'NEGATIVE'
               ELSE CONCAT('$', ib_lower_bound, ' - $', ib_upper_bound)
           END AS income_description
    FROM income_band
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_purchase_estimate, cd.cd_credit_rating, 
           RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_purchase,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_dep_count DESC) AS row_number_deps,
           i.income_description
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN income_ranges i ON hd.hd_income_band_sk = i.ib_income_band_sk
    WHERE cd.cd_gender IS NOT NULL AND cd.cd_purchase_estimate IS NOT NULL
),
sales_data AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_net_profit,
           MIN(ws.ws_net_paid) AS min_net_paid,
           MAX(ws.ws_net_paid) AS max_net_paid,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
detailed_sales AS (
    SELECT ci.*, sd.total_quantity, sd.total_net_profit, sd.min_net_paid, sd.max_net_paid, sd.order_count
    FROM customer_info ci
    LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
)
SELECT d.c_first_name, d.c_last_name, 
       COALESCE(d.income_description, 'UNKNOWN') AS income_description,
       d.total_quantity, d.total_net_profit,
       CASE 
           WHEN d.total_quantity IS NULL THEN 'No Sales'
           WHEN d.total_quantity > 100 THEN 'High Volume'
           ELSE 'Low Volume'
       END AS sales_category,
       ROW_NUMBER() OVER (ORDER BY d.total_net_profit DESC) AS profit_rank
FROM detailed_sales d
WHERE d.rank_purchase = 1
  AND d.row_number_deps <= 2
ORDER BY profit_rank ASC;
