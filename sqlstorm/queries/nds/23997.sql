
WITH  date_range AS (
    SELECT MIN(d_date) AS start_date, MAX(d_date) AS end_date
    FROM date_dim
),
current_income AS (
    SELECT cd_demo_sk, cd_gender,
           CASE
               WHEN hd_income_band_sk IS NOT NULL THEN (SELECT COUNT(*) FROM household_demographics WHERE hd_income_band_sk = cd_demo_sk)
               ELSE NULL
           END AS income_count
    FROM customer_demographics
    LEFT JOIN household_demographics ON cd_demo_sk = hd_demo_sk
    WHERE cd_purchase_estimate > 1000
),
sales_data AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_net_profit) AS total_profit,
           AVG(ws_sales_price) AS avg_price,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = (SELECT start_date FROM date_range)) 
                                 AND (SELECT d_date_sk FROM date_dim WHERE d_date = (SELECT end_date FROM date_range))
    GROUP BY ws_item_sk
),
item_analysis AS (
    SELECT i.i_item_sk, i.i_item_desc, 
           COALESCE(sd.total_quantity, 0) AS quantity_sold,
           COALESCE(sd.total_profit, 0) AS total_profit,
           COALESCE(sd.order_count, 0) AS orders,
           PERCENT_RANK() OVER (ORDER BY COALESCE(sd.total_profit, 0) DESC) AS profit_rank,
           CASE 
               WHEN COALESCE(sd.total_profit, 0) = 0 THEN 'No Profit'
               ELSE 'Profitable'
           END AS profitability
    FROM item i
    LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
),

join_example AS (
    SELECT cu.c_first_name,
           cu.c_last_name,
           COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
           SUM(CASE WHEN not (cu.c_first_name IS NULL OR cu.c_last_name IS NULL) THEN 1 ELSE 0 END) AS non_null_names
    FROM customer cu
    LEFT JOIN catalog_sales cs ON cu.c_customer_sk = cs.cs_bill_customer_sk
    WHERE cu.c_birth_year IS NOT NULL AND (cu.c_birth_month IS NULL OR cu.c_birth_month < 6)
    GROUP BY cu.c_first_name, cu.c_last_name
    HAVING COUNT(DISTINCT cs.cs_order_number) > 0
)

SELECT ia.i_item_sk,
       ia.i_item_desc,
       ia.quantity_sold,
       ia.total_profit,
       ia.profitability,
       je.c_first_name,
       je.c_last_name,
       je.catalog_order_count,
       je.non_null_names
FROM item_analysis ia
JOIN join_example je ON ia.i_item_sk = je.catalog_order_count
WHERE ia.profit_rank < 0.1 AND je.catalog_order_count > 5
ORDER BY ia.total_profit DESC, ia.i_item_sk ASC
LIMIT 10 OFFSET 0;
