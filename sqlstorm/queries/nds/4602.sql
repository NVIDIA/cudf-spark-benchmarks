
WITH ranked_sales AS (
    SELECT ws.ws_item_sk,
           ws.ws_order_number,
           ws.ws_quantity,
           ws.ws_sales_price,
           RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
           (SELECT SUM(ws1.ws_quantity)
            FROM web_sales ws1
            WHERE ws1.ws_item_sk = ws.ws_item_sk
              AND ws1.ws_order_number < ws.ws_order_number) AS cumulative_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1000 AND 2000
),
customer_data AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           hd.hd_income_band_sk,
           CASE 
               WHEN hd.hd_income_band_sk IS NOT NULL THEN 'Income Band'
               ELSE 'No Income Band' 
           END AS income_band_status
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
final_results AS (
    SELECT cd.c_customer_sk,
           cd.c_first_name,
           cd.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
           COUNT(DISTINCT rs.ws_order_number) AS total_orders,
           MAX(rs.price_rank) AS max_price_rank
    FROM customer_data cd
    LEFT JOIN ranked_sales rs ON cd.c_customer_sk = rs.ws_item_sk
    GROUP BY cd.c_customer_sk, cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT f.*, 
       CASE 
           WHEN f.total_sales IS NULL THEN 'No Sales'
           WHEN f.total_sales >= 1000 THEN 'High Value Customer'
           ELSE 'Low Value Customer'
       END AS customer_segment
FROM final_results f
WHERE f.total_orders > 5
  AND f.total_sales IS NOT NULL
ORDER BY f.total_sales DESC
LIMIT 10 OFFSET 0;
