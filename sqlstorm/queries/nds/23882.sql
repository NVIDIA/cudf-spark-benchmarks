
WITH  income_ranges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
),
customer_incomes AS (
    SELECT c.c_customer_sk, c.c_customer_id, h.hd_income_band_sk, h.hd_dep_count, h.hd_vehicle_count,
           CASE 
               WHEN h.hd_dep_count IS NULL OR h.hd_vehicle_count IS NULL 
               THEN 'Unspecified'
               ELSE CONCAT('Dependents: ', CAST(h.hd_dep_count AS STRING), ', Vehicles: ', CAST(h.hd_vehicle_count AS STRING))
           END AS income_info
    FROM customer c
    LEFT JOIN household_demographics h ON c.c_customer_sk = h.hd_demo_sk
),
monthly_sales AS (
    SELECT d.d_month_seq, SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_month_seq
),
high_sales AS (
    SELECT m.d_month_seq, m.total_sales,
           RANK() OVER (ORDER BY m.total_sales DESC) AS sales_rank
    FROM monthly_sales m
    WHERE m.total_sales IS NOT NULL
),
address_info AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT ci.c_customer_id, 
       ci.income_info, 
       hs.total_sales, 
       ai.customer_count,
       CASE 
           WHEN hs.sales_rank <= 5 THEN 'Top Sales'
           ELSE 'Regular Sales'
       END AS sales_category,
       CASE 
           WHEN EXISTS (SELECT 1 FROM customer_demographics cd WHERE cd.cd_demo_sk = ci.hd_income_band_sk AND cd.cd_gender = 'F') 
           THEN 'Female Customers Found'
           ELSE 'No Female Customers'
       END AS female_status
FROM customer_incomes ci
LEFT JOIN high_sales hs ON ci.hd_income_band_sk = hs.d_month_seq
LEFT JOIN address_info ai ON ci.c_customer_sk = ai.customer_count
WHERE (ai.customer_count IS NOT NULL OR ci.hd_dep_count > 2)
  AND (ci.hd_vehicle_count IS NOT NULL OR ci.hd_dep_count IS NULL)
ORDER BY hs.total_sales DESC NULLS LAST
LIMIT 1000;
