
WITH date_range AS (
    SELECT d.d_date_sk, d.d_year
    FROM date_dim d
    WHERE d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           cd.cd_education_status, cd.cd_purchase_estimate, cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_sales_price) AS total_sales, SUM(ws.ws_quantity) AS total_quantity,
           ws.ws_bill_cdemo_sk, dr.d_year
    FROM web_sales ws
    JOIN date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
    GROUP BY ws.ws_item_sk, ws.ws_bill_cdemo_sk, dr.d_year
),
customer_sales AS (
    SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status,
           ci.cd_education_status, ci.cd_purchase_estimate, ci.cd_credit_rating,
           sd.total_sales, sd.total_quantity, sd.d_year
    FROM customer_info ci
    JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_cdemo_sk
)
SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.cd_gender, c.cd_marital_status,
       c.cd_education_status, c.cd_purchase_estimate, c.cd_credit_rating,
       SUM(COALESCE(c.total_sales, 0)) AS total_sales, 
       SUM(COALESCE(c.total_quantity, 0)) AS total_quantity,
       c.d_year
FROM customer_sales c
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.cd_gender, 
         c.cd_marital_status, c.cd_education_status, c.cd_purchase_estimate, 
         c.cd_credit_rating, c.d_year
HAVING SUM(COALESCE(c.total_sales, 0)) > 10000
ORDER BY total_sales DESC
LIMIT 100;
