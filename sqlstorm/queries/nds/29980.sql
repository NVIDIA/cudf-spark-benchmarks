
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_number) || ' ' || TRIM(ca_street_name) || ' ' || TRIM(ca_street_type) || 
        CASE 
            WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN ' Suite ' || TRIM(ca_suite_number)
            ELSE '' 
        END AS full_address
    FROM customer_address
), demographics AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Mr.' 
            WHEN cd_gender = 'F' THEN 'Ms.' 
            ELSE 'Unknown' 
        END AS salutation,
        cd_marital_status AS marital_status,
        cd_education_status AS education_status,
        cd_credit_rating,
        cd_dep_count
    FROM customer_demographics
), summarized_data AS (
    SELECT 
        ca.ca_address_sk,
        ca.full_address,
        cd.salutation,
        cd.marital_status,
        cd.education_status,
        COUNT(DISTINCT cd.cd_demo_sk) AS total_demographics
    FROM processed_addresses ca
    JOIN demographics cd ON cd.cd_demo_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.full_address, cd.salutation, cd.marital_status, cd.education_status
)
SELECT 
    sd.full_address,
    sd.salutation,
    sd.marital_status,
    sd.education_status,
    sd.total_demographics
FROM summarized_data sd
WHERE sd.total_demographics > 0
ORDER BY sd.total_demographics DESC
LIMIT 100;
