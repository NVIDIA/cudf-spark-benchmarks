
WITH AddressData AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
CombinedData AS (
    SELECT 
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        de.cd_gender,
        de.cd_marital_status,
        de.cd_education_status,
        de.cd_purchase_estimate,
        de.cd_credit_rating
    FROM 
        AddressData ad
    JOIN 
        Demographics de ON ad.ca_country = CASE 
            WHEN de.cd_gender = 'M' THEN 'USA' 
            ELSE 'Canada' 
        END
),
StringMetrics AS (
    SELECT 
        full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(full_address) AS address_length,
        LOWER(full_address) AS address_lowercase,
        UPPER(full_address) AS address_uppercase,
        POSITION('Street' IN full_address) AS street_position
    FROM 
        CombinedData
)
SELECT 
    CONCAT(full_address, ' ', ca_city, ', ', ca_state, ' ', ca_zip, ' ', ca_country) AS detailed_address,
    address_length,
    address_lowercase,
    address_uppercase,
    street_position
FROM 
    StringMetrics
WHERE 
    address_length > 30
ORDER BY 
    address_length DESC
LIMIT 100;
