
WITH  demo_cte AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status, cd_purchase_estimate, 
           ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rn
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
),
filtered_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_paid) AS total_sales,
           COUNT(ws_order_number) AS order_count,
           MAX(ws_sales_price) AS max_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
)
SELECT f.c_customer_sk, f.c_first_name, f.c_last_name, f.ca_city, f.ca_state,
       d.cd_gender, d.cd_marital_status, 
       COALESCE(s.total_sales, 0) AS total_sales, 
       COALESCE(s.order_count, 0) AS order_count,
       s.max_sales_price,
       (CASE
           WHEN d.cd_gender = 'F' THEN 'Female'
           WHEN d.cd_gender = 'M' THEN 'Male'
           ELSE 'Other'
        END) AS gender_description
FROM filtered_customers f
LEFT JOIN demo_cte d ON f.cd_gender = d.cd_gender AND d.rn <= 5
LEFT JOIN sales_summary s ON f.c_customer_sk = s.ws_bill_customer_sk
WHERE f.ca_state IN ('CA', 'NY')
ORDER BY total_sales DESC, f.c_last_name ASC
LIMIT 100;
