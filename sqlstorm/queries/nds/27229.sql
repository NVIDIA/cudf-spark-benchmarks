WITH AddressProcessing AS (
    SELECT
        ca_address_sk,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length,
        REGEXP_REPLACE(ca_city, '[^A-Za-z0-9 ]', '') AS sanitized_city,
        SUBSTRING(ca_zip, 1, 5) AS zip_prefix
    FROM
        customer_address
),
DemographicsProcessing AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        UPPER(cd_marital_status) AS marital_status,
        TRIM(cd_education_status) AS education_status
    FROM
        customer_demographics
),
CombinedData AS (
    SELECT
        a.ca_address_sk,
        a.full_address,
        a.address_length,
        a.sanitized_city,
        d.cd_demo_sk,
        d.cd_gender,
        d.marital_status,
        d.education_status
    FROM
        AddressProcessing a
    JOIN
        DemographicsProcessing d ON a.ca_address_sk % 1000 = d.cd_demo_sk % 1000 
)
SELECT
    cd_gender,
    COUNT(*) AS total_customers,
    AVG(address_length) AS avg_address_length,
    COUNT(DISTINCT sanitized_city) AS unique_cities
FROM
    CombinedData
GROUP BY
    cd_gender
ORDER BY
    total_customers DESC;