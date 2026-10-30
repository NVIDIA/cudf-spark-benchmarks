
WITH AddressInfo AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND 
        ca_state IS NOT NULL AND 
        ca_zip IS NOT NULL
),
AddressCounts AS (
    SELECT 
        full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(full_address) AS address_length,
        CHAR_LENGTH(full_address) AS address_char_length,
        COUNT(*) AS address_count
    FROM 
        AddressInfo
    GROUP BY 
        full_address, ca_city, ca_state, ca_zip
),
DemographicsInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
Metrics AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        SUM(d.cd_purchase_estimate) AS total_purchase_estimate,
        AVG(a.address_length) AS avg_address_length,
        SUM(a.address_count) AS total_addresses,
        COUNT(DISTINCT d.cd_gender) AS unique_genders,
        COUNT(DISTINCT d.cd_marital_status) AS unique_marital_statuses
    FROM 
        AddressCounts a
    JOIN 
        DemographicsInfo d 
    ON 
        (a.ca_city = d.cd_marital_status) 
    GROUP BY 
        a.ca_city, a.ca_state, a.ca_zip
)
SELECT 
    ca_city,
    ca_state,
    ca_zip,
    total_purchase_estimate,
    avg_address_length,
    total_addresses,
    unique_genders,
    unique_marital_statuses
FROM 
    Metrics
WHERE 
    total_addresses > 10 
ORDER BY 
    total_purchase_estimate DESC, 
    avg_address_length ASC;
