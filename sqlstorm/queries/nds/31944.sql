
WITH  sales_stats AS (
    SELECT ws_item_sk, 
           SUM(ws_sales_price) AS total_sales, 
           COUNT(ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) as sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           hd.hd_income_band_sk,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) as customer_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), 
sales_by_income AS (
    SELECT ci.c_first_name,
           ci.c_last_name,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           ss.total_sales,
           ss.order_count
    FROM customer_info ci
    JOIN sales_stats ss ON ci.c_customer_sk = ss.ws_item_sk
    JOIN income_band ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.total_sales > 1000 
      AND (ci.hd_income_band_sk IS NOT NULL OR ci.hd_income_band_sk IS NULL)
)
SELECT *
FROM sales_by_income
WHERE order_count > (SELECT AVG(order_count) FROM sales_stats)
UNION
SELECT ci.c_first_name,
       ci.c_last_name,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       0 AS total_sales,
       0 AS order_count
FROM customer_info ci
LEFT JOIN income_band ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
WHERE ci.c_customer_sk NOT IN (SELECT ws_item_sk FROM web_sales)
ORDER BY total_sales DESC, c_first_name;
