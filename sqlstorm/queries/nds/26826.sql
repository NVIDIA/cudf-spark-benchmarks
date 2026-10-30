
WITH Address AS (
    SELECT ca_address_sk, 
           CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
           LOWER(ca_city) AS city_lower,
           ca_state AS state_code,
           ca_zip AS postal_code,
           ca_country AS country_name 
    FROM customer_address
),
Demographics AS (
    SELECT cd_demo_sk, 
           cd_gender, 
           cd_marital_status, 
           cd_education_status, 
           cd_purchase_estimate, 
           CONCAT(cd_dep_count, ' dependents') AS deps_info 
    FROM customer_demographics
),
Sales AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_sales_price) AS total_sales, 
           COUNT(ws_order_number) AS order_count 
    FROM web_sales 
    GROUP BY ws_bill_customer_sk
)
SELECT CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
       a.full_address,
       d.cd_gender,
       d.cd_marital_status,
       d.deps_info,
       s.total_sales,
       s.order_count
FROM customer AS c
JOIN Address AS a ON c.c_current_addr_sk = a.ca_address_sk
JOIN Demographics AS d ON c.c_current_cdemo_sk = d.cd_demo_sk
LEFT JOIN Sales AS s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE a.city_lower LIKE '%cityname%'
  AND d.cd_marital_status = 'M'
ORDER BY s.total_sales DESC
LIMIT 10;
