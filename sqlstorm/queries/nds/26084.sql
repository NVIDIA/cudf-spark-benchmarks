
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip
    FROM customer_address
),
demographic_info AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, ' ', cd_marital_status) AS gender_marital,
        cd_education_status
    FROM customer_demographics
),
composite_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.full_address,
        a.city_state_zip,
        d.gender_marital,
        d.cd_education_status
    FROM customer c
    JOIN address_parts a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN demographic_info d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    full_name,
    full_address,
    city_state_zip,
    gender_marital,
    cd_education_status,
    LENGTH(full_address) AS address_length,
    SUBSTRING(full_name, 1, 10) AS name_preview
FROM composite_data
WHERE cd_education_status LIKE '%University%'
ORDER BY address_length DESC, full_name ASC
LIMIT 100;
