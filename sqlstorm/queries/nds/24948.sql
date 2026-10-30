
WITH  customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ROW_NUMBER() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY c.c_customer_id) AS customer_rank
    FROM customer c
    WHERE c.c_birth_year IS NOT NULL
),
customer_details AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, cd.cd_gender, 
           cd.cd_marital_status, cd.cd_education_status,
           COALESCE(cd.cd_purchase_estimate, 0) * NULLIF(cd.cd_dep_count, 0) AS total_estimated_income,
           ROW_NUMBER() OVER (PARTITION BY ch.c_current_cdemo_sk ORDER BY ch.c_customer_sk DESC) AS rank_with_income
    FROM customer_hierarchy ch
    JOIN customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
),
inventory_values AS (
    SELECT I.inv_item_sk, 
           SUM(I.inv_quantity_on_hand) AS total_quantity
    FROM inventory I
    GROUP BY I.inv_item_sk
),
sales AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_sales_price) AS total_sales_amount
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= 20220301
    GROUP BY ws.ws_item_sk
),
final_output AS (
    SELECT cd.c_first_name, cd.c_last_name, cd.cd_gender, 
           iv.total_quantity,
           COALESCE(s.total_sales_amount, 0) AS web_sales,
           CASE 
               WHEN cd.total_estimated_income > 0 THEN (s.total_sales_amount / cd.total_estimated_income) 
               ELSE NULL 
           END AS sales_to_income_ratio
    FROM customer_details cd
    LEFT JOIN inventory_values iv ON cd.c_customer_sk = iv.inv_item_sk
    LEFT JOIN sales s ON cd.c_customer_sk = s.ws_item_sk
    WHERE cd.rank_with_income = 1
)
SELECT f.c_first_name, f.c_last_name, f.cd_gender,
       f.total_quantity, f.web_sales, 
       CASE 
           WHEN f.sales_to_income_ratio IS NULL THEN 'No Sales Data'
           WHEN f.sales_to_income_ratio < 0.1 THEN 'Low Ratio'
           WHEN f.sales_to_income_ratio BETWEEN 0.1 AND 1 THEN 'Moderate Ratio'
           ELSE 'High Ratio'
       END AS sales_status,
       f.web_sales || ' & ' || COALESCE(CAST(f.total_quantity AS STRING), 'N/A') AS sales_and_quantity
FROM final_output f
ORDER BY f.web_sales DESC, f.total_quantity DESC
LIMIT 10;
