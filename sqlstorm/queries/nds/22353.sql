
WITH  income_levels AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound, 
           ROW_NUMBER() OVER (ORDER BY ib_lower_bound) AS rn
    FROM income_band
),
sales_data AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, 
           SUM(ws_sales_price) AS total_sales, 
           DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk
                               FROM date_dim
                               WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
demographics_with_sales AS (
    SELECT cd.cd_gender, cd.cd_marital_status, cd.cd_demo_sk, 
           SUM(sd.total_sales) AS demo_sales,
           COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer_demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN sales_data sd ON c.c_customer_sk = sd.ws_item_sk
    WHERE (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F')
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_demo_sk
),
store_info AS (
    SELECT s.s_store_sk, s.s_store_name, SUM(ss.ss_net_profit) AS total_net_profit, 
           AVG(ss.ss_net_paid) AS avg_net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY s.s_store_sk, s.s_store_name
)
SELECT dws.cd_marital_status, dws.cd_gender, 
       COALESCE(si.total_net_profit, 0) AS store_profit, 
       COALESCE(dws.customer_count, 0) AS cust_count,
       il.ib_lower_bound, il.ib_upper_bound
FROM demographics_with_sales dws
FULL OUTER JOIN income_levels il ON dws.demo_sales BETWEEN il.ib_lower_bound AND il.ib_upper_bound
LEFT JOIN store_info si ON dws.cd_demo_sk = si.s_store_sk
WHERE dws.demo_sales IS NOT NULL OR (il.ib_lower_bound IS NULL AND il.ib_upper_bound IS NULL)
ORDER BY dws.cd_gender, dws.cd_marital_status, store_profit DESC
LIMIT 100 OFFSET 50;
