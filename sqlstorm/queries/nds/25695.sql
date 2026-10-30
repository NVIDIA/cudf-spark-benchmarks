
WITH CustomerInfo AS (
    SELECT c.c_customer_sk,
           CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           ca.ca_city,
           ca.ca_state,
           ca.ca_zip,
           ca.ca_country
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales AS ws
    WHERE ws.ws_sold_date_sk > (
        SELECT MAX(d.d_date_sk)
        FROM date_dim AS d
        WHERE d.d_year = 2022
    )
    GROUP BY ws.ws_bill_customer_sk
),
FinalReport AS (
    SELECT ci.full_name,
           ci.ca_city,
           ci.ca_state,
           ci.ca_zip,
           ci.ca_country,
           COALESCE(sd.total_sales, 0) AS total_sales,
           COALESCE(sd.total_orders, 0) AS total_orders,
           CASE 
               WHEN COALESCE(sd.total_sales, 0) > 1000 THEN 'High Value'
               WHEN COALESCE(sd.total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS customer_value_category
    FROM CustomerInfo AS ci
    LEFT JOIN SalesData AS sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT *,
       CONCAT('[', full_name, '] - ', customer_value_category) AS customer_profile
FROM FinalReport
ORDER BY total_sales DESC;
