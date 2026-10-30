
WITH AddressStats AS (
    SELECT
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS full_addresses
    FROM
        customer_address
    GROUP BY
        ca_state
),
CustomerDemographicStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS demographic_count,
        STRING_AGG(CONCAT(cd_marital_status, ' - ', cd_education_status), ', ') AS demographics
    FROM
        customer_demographics
    GROUP BY
        cd_gender
)
SELECT 
    A.ca_state,
    A.address_count,
    A.cities,
    A.full_addresses,
    C.cd_gender,
    C.demographic_count,
    C.demographics
FROM 
    AddressStats A
JOIN 
    CustomerDemographicStats C ON A.address_count > C.demographic_count
ORDER BY 
    A.address_count DESC, C.demographic_count ASC
LIMIT 100;
