
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(REGEXP_REPLACE(ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type || ' ' || COALESCE(ca_suite_number, '') || ', ' || ca_city || ', ' || ca_state || ' ' || ca_zip, '[^a-zA-Z0-9, ]', '')) AS full_address,
        LENGTH(TRIM(ca_street_name)) AS street_name_length,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_state) AS state_upper
    FROM customer_address
),
DemographicInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        TRIM(cd_education_status) AS education_status,
        cd_purchase_estimate
    FROM customer_demographics
)
SELECT 
    a.ca_address_sk,
    a.full_address,
    d.cd_demo_sk,
    d.cd_gender,
    d.cd_marital_status,
    a.street_name_length,
    d.education_status,
    SUM(d.cd_purchase_estimate) OVER (PARTITION BY d.cd_gender ORDER BY a.full_address) AS cumulative_purchase_estimate,
    CONCAT(a.city_lower, ', ', a.state_upper) AS formatted_location
FROM AddressParts a
JOIN DemographicInfo d ON a.ca_address_sk = d.cd_demo_sk
WHERE a.street_name_length > 5
ORDER BY a.full_address, d.cd_gender DESC
LIMIT 100;
