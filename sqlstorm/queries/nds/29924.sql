
WITH CustomerAddresses AS (
    SELECT ca_address_sk, 
           CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
                  COALESCE(CONCAT(' ', ca_suite_number), '')) AS full_address,
           ca_city,
           ca_state,
           ca_zip,
           ca_country
    FROM customer_address
),
Demographics AS (
    SELECT cd_demo_sk, 
           cd_gender,
           cd_marital_status,
           cd_education_status,
           cd_purchase_estimate,
           cd_credit_rating,
           cd_dep_count
    FROM customer_demographics
    WHERE cd_purchase_estimate > 1000
),
CustomerInfo AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           c.c_email_address,
           ca.full_address,
           d.cd_gender,
           d.cd_marital_status,
           ca.ca_city,
           ca.ca_state
    FROM customer c
    JOIN CustomerAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT ci.c_first_name, 
       ci.c_last_name, 
       ci.c_email_address,
       ci.full_address,
       COUNT(*) OVER (PARTITION BY ci.ca_city, ci.ca_state) AS count_per_city_state,
       CONCAT(ci.cd_gender, ' - ', ci.cd_marital_status) AS gender_marital_status
FROM CustomerInfo ci
ORDER BY count_per_city_state DESC, ci.c_last_name, ci.c_first_name;
