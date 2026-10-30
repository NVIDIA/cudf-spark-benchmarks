
WITH processed_addresses AS (
    SELECT ca_address_sk,
           TRIM(UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type))) AS normalized_address,
           ca_city,
           ca_state,
           ca_zip
    FROM customer_address
),
customer_info AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           cd.cd_purchase_estimate,
           ca.normalized_address,
           ca.ca_city,
           ca.ca_state,
           ca.ca_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN processed_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
),
date_info AS (
    SELECT d.d_date_sk,
           d.d_year,
           d.d_month_seq,
           d.d_day_name
    FROM date_dim d
    WHERE d.d_year >= 2020
),
sales_info AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_info di ON ws.ws_sold_date_sk = di.d_date_sk
    GROUP BY ws.ws_bill_customer_sk
),
benchmark_result AS (
    SELECT ci.c_customer_sk,
           ci.c_first_name,
           ci.c_last_name,
           ci.cd_gender,
           ci.cd_marital_status,
           ci.cd_education_status,
           ci.cd_purchase_estimate,
           si.total_quantity,
           si.total_sales,
           si.order_count,
           CONCAT(ci.normalized_address, ', ', ci.ca_city, ', ', ci.ca_state, ' ', ci.ca_zip) AS full_address
    FROM customer_info ci
    LEFT JOIN sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT *,
       CASE
           WHEN total_sales IS NULL THEN 'No Sales'
           WHEN total_sales < 1000 THEN 'Low Sales'
           WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Medium Sales'
           ELSE 'High Sales'
       END AS sales_category
FROM benchmark_result
ORDER BY total_sales DESC, c_last_name ASC, c_first_name ASC
LIMIT 100;
