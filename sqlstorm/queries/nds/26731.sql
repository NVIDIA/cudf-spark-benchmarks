WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length,
        LENGTH(ca_state) AS state_length
    FROM customer_address
),
DemographicInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        CONCAT(cd_gender, '-', cd_marital_status) AS gender_marital,
        LENGTH(cd_credit_rating) AS credit_length
    FROM customer_demographics
),
CombinedInfo AS (
    SELECT 
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.gender_marital,
        a.street_name_length + d.credit_length AS total_length
    FROM AddressInfo a
    JOIN DemographicInfo d ON a.ca_address_sk = d.cd_demo_sk 
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    gender_marital,
    AVG(total_length) AS avg_length,
    COUNT(*) AS record_count
FROM CombinedInfo
GROUP BY 
    full_address, 
    ca_city, 
    ca_state, 
    ca_zip, 
    gender_marital
ORDER BY avg_length DESC
LIMIT 10;