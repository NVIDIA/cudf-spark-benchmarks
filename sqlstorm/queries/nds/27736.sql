
WITH customer_info AS (
    SELECT c.c_customer_sk, CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_education_status 
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), formatted_addresses AS (
    SELECT ca.ca_address_sk, CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
           CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) ELSE '' END, 
           ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address 
    FROM customer_address ca
), sale_summary AS (
    SELECT ws.ws_bill_customer_sk, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
), address_sales AS (
    SELECT ci.full_name, ci.cd_gender, ci.cd_marital_status, ci.cd_education_status,
           fa.full_address, COALESCE(ss.total_sales, 0) AS total_sales
    FROM customer_info ci
    LEFT JOIN formatted_addresses fa ON ci.c_customer_sk = fa.ca_address_sk
    LEFT JOIN sale_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT *, 
       CASE 
           WHEN total_sales > 1000 THEN 'High Value'
           WHEN total_sales > 500 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value_category
FROM address_sales
ORDER BY total_sales DESC;
