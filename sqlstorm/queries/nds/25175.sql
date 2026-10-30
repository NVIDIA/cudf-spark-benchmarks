
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        LOWER(ca_city) AS lower_city,
        LOWER(ca_state) AS lower_state,
        LOWER(ca_country) AS lower_country
    FROM customer_address
), FormattedDemographics AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, ' ', cd_marital_status, ' ', cd_education_status) AS demographic_info,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer_demographics
), JoinedData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.full_address,
        d.demographic_info,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count,
        d.cd_dep_employed_count,
        d.cd_dep_college_count,
        a.lower_city,
        a.lower_state,
        a.lower_country
    FROM customer c
    JOIN AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN FormattedDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    full_name,
    full_address,
    demographic_info,
    cd_purchase_estimate,
    cd_credit_rating,
    cd_dep_count,
    cd_dep_employed_count,
    cd_dep_college_count,
    CONCAT(lower_city, ', ', lower_state, ', ', lower_country) AS normalized_location
FROM JoinedData
WHERE cd_purchase_estimate > 1000 
ORDER BY cd_purchase_estimate DESC
LIMIT 100;
