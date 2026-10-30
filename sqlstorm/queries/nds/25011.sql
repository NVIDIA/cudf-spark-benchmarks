WITH AddressInfo AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM customer_demographics
),
TopCities AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count
    FROM customer_address
    GROUP BY ca_city
    HAVING COUNT(*) > 100
),
CombinedData AS (
    SELECT 
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating
    FROM AddressInfo a
    JOIN Demographics d ON a.ca_city = d.cd_gender  
    WHERE a.ca_city IN (SELECT ca_city FROM TopCities)
)
SELECT 
    CONCAT(REPLACE(UPPER(full_address), ' ', '_'), ' - ', LOWER(ca_city)) AS address_key,
    COUNT(*) AS record_count,
    AVG(cd_purchase_estimate) AS average_purchase_estimate
FROM CombinedData
GROUP BY address_key
ORDER BY record_count DESC
LIMIT 10;