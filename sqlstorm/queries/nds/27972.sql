
WITH customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_education_status,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           CASE 
               WHEN cd.cd_gender = 'M' THEN 'Male'
               WHEN cd.cd_gender = 'F' THEN 'Female'
               ELSE 'Other' 
           END AS gender_description
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country,
           CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', 
                  ca.ca_street_type, ', ', ca.ca_suite_number) AS full_address
    FROM customer_address ca
),
sales_data AS (
    SELECT ws.ws_bill_customer_sk, SUM(ws.ws_sales_price) AS total_spent
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT ci.full_name, ci.gender_description, ai.full_address, 
       COALESCE(sd.total_spent, 0) AS total_spent
FROM customer_info ci
JOIN address_info ai ON ci.c_customer_sk = ai.ca_address_sk
LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE ai.ca_country = 'USA'
ORDER BY total_spent DESC;
