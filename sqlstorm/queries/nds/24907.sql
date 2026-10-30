
WITH  address_cte AS (
    SELECT ca_address_sk, ca_country, ca_city, ca_state, ca_zip,
           ROW_NUMBER() OVER (PARTITION BY ca_country ORDER BY ca_address_sk) AS rn
    FROM customer_address
    WHERE ca_country IS NOT NULL
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address,
           cd.cd_gender, cd.cd_marital_status, 
           COALESCE(hd.hd_income_band_sk, -1) AS income_band,
           CASE 
               WHEN cd.cd_marital_status = 'M' THEN 'Married'
               ELSE 'Single' 
           END AS marital_status_label
    FROM customer c 
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
sales_summary AS (
    SELECT ws_bill_customer_sk, SUM(ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS total_orders, 
           AVG(ws_net_paid) AS avg_paid
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT ci.c_first_name, ci.c_last_name, ci.c_email_address, 
       a.ca_city, a.ca_state,
       COALESCE(ss.total_sales, 0) AS total_sales,
       CASE
           WHEN ss.total_sales IS NULL THEN 'No Sales'
           WHEN ss.total_sales > 1000 THEN 'Top Customer'
           ELSE 'Regular Customer' 
       END AS customer_status,
       ROW_NUMBER() OVER (PARTITION BY a.ca_state ORDER BY ss.total_sales DESC) AS rank_in_state,
       CASE
           WHEN ci.marital_status_label = 'Married' AND ci.income_band = 3 THEN 'Focus Marketing'
           ELSE NULL 
       END AS marketing_target
FROM customer_info ci
LEFT JOIN address_cte a ON ci.c_customer_sk = a.ca_address_sk 
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE a.rn <= 5
  AND (ci.c_email_address LIKE '%@example.com' OR ci.c_email_address IS NULL)
ORDER BY customer_status, rank_in_state
LIMIT 30 OFFSET 10;
