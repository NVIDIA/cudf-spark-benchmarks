
WITH normalized_addresses AS (
    SELECT
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' ', TRIM(ca_suite_number)) END, 
               ', ', TRIM(ca_city), ', ', TRIM(ca_state), ' ', TRIM(ca_zip), ' ', TRIM(ca_country)) AS full_address
    FROM
        customer_address
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        d.d_date AS registration_date,
        ca.full_address
    FROM
        customer c
    JOIN
        date_dim d ON c.c_first_shipto_date_sk = d.d_date_sk
    JOIN
        normalized_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
),
demographic_info AS (
    SELECT
        ci.c_customer_sk,
        ci.full_name,
        ci.full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM
        customer_info ci
    JOIN
        customer_demographics cd ON ci.c_customer_sk = cd.cd_demo_sk
)
SELECT
    di.full_name,
    di.full_address,
    di.cd_gender,
    di.cd_marital_status,
    di.cd_education_status,
    di.cd_purchase_estimate,
    CASE
        WHEN di.cd_purchase_estimate BETWEEN 0 AND 1000 THEN 'Low'
        WHEN di.cd_purchase_estimate BETWEEN 1001 AND 5000 THEN 'Medium'
        ELSE 'High'
    END AS purchase_estimate_band
FROM
    demographic_info di
WHERE
    di.cd_gender = 'F' AND di.cd_marital_status = 'S'
ORDER BY
    di.cd_purchase_estimate DESC
LIMIT 100;
