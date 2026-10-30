
WITH customer_info AS (
    SELECT c.c_customer_sk, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
           cd.cd_gender, 
           ca.ca_city, 
           ca.ca_state, 
           cd.cd_marital_status, 
           cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
date_filter AS (
    SELECT d.d_date_sk
    FROM date_dim d
    WHERE d.d_date >= '2023-01-01' AND d.d_date < '2023-12-31'
),
sales_data AS (
    SELECT ws.ws_bill_customer_sk, 
           SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_filter df ON ws.ws_sold_date_sk = df.d_date_sk
    GROUP BY ws.ws_bill_customer_sk
),
aggregated_data AS (
    SELECT ci.full_name, 
           ci.ca_city, 
           ci.ca_state, 
           ci.cd_gender, 
           ci.cd_marital_status, 
           ci.cd_education_status, 
           COALESCE(sd.total_sales, 0) AS total_sales
    FROM customer_info ci
    LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT COUNT(*) AS total_customers, 
       AVG(total_sales) AS average_sales, 
       COUNT(CASE WHEN total_sales > 0 THEN 1 END) AS customers_with_sales 
FROM aggregated_data
WHERE ca_city IS NOT NULL 
  AND cd_education_status IN ('Bachelors', 'Masters')
GROUP BY ca_state, full_name, ca_city, cd_gender, cd_marital_status, cd_education_status
ORDER BY average_sales DESC;
