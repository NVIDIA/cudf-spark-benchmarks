
WITH  income_distribution AS (
    SELECT ib_income_band_sk,
           ib_lower_bound,
           ib_upper_bound,
           ROW_NUMBER() OVER (ORDER BY ib_lower_bound) AS rn
    FROM income_band
),
customer_sales AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c_birth_year,
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count,
           MAX(ws_net_profit) AS highest_profit,
           CASE 
               WHEN COUNT(DISTINCT ws_order_number) = 0 THEN 'N/A'
               ELSE CAST(ROUND(SUM(ws_ext_sales_price) / COUNT(DISTINCT ws_order_number), 2) AS VARCHAR(10))
           END AS avg_sales_per_order
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c_birth_year
),
avg_sales AS (
    SELECT AVG(total_sales) AS overall_avg_sales
    FROM customer_sales
),
sales_analysis AS (
    SELECT cs.c_customer_sk,
           cs.c_first_name,
           cs.c_last_name,
           cs.total_sales,
           cs.order_count,
           CASE 
               WHEN cs.total_sales > a.overall_avg_sales THEN 'Above Average'
               WHEN cs.total_sales < a.overall_avg_sales THEN 'Below Average'
               ELSE 'Average'
           END AS sales_category,
           ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound
    FROM customer_sales cs
    CROSS JOIN avg_sales a
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cs.c_customer_sk
    LEFT JOIN income_distribution ib ON (cs.total_sales BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound)
)
SELECT sa.sales_category,
       COUNT(DISTINCT sa.c_customer_sk) AS customer_count,
       ROUND(AVG(sa.total_sales), 2) AS avg_total_sales,
       SUM(sa.order_count) AS total_orders,
       MIN(sa.ib_lower_bound) AS min_income_band,
       MAX(sa.ib_upper_bound) AS max_income_band,
       ARRAY_AGG(DISTINCT sa.c_first_name || ' ' || sa.c_last_name) AS customer_names,
       SUM(CASE WHEN sa.total_sales IS NULL THEN 1 ELSE 0 END) AS null_sales_count,
       COUNT(*) FILTER (WHERE sa.total_sales IS NOT NULL) AS not_null_sales_count
FROM sales_analysis sa
GROUP BY sa.sales_category
ORDER BY sa.sales_category;
