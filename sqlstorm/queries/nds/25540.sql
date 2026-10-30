
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        LTRIM(RTRIM(ca_zip)) AS cleaned_zip
    FROM 
        customer_address
), AddressStatistics AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        COUNT(DISTINCT ca_city) AS distinct_city_count,
        MAX(LENGTH(full_address)) AS max_address_length,
        MIN(LENGTH(full_address)) AS min_address_length,
        AVG(LENGTH(full_address)) AS avg_address_length
    FROM 
        ProcessedAddresses
    GROUP BY 
        ca_state
), DemographicDistribution AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)

SELECT 
    A.ca_state,
    A.address_count,
    A.distinct_city_count,
    A.max_address_length,
    A.min_address_length,
    A.avg_address_length,
    D.cd_gender,
    D.gender_count,
    D.avg_purchase_estimate
FROM 
    AddressStatistics A
LEFT JOIN 
    DemographicDistribution D ON A.address_count > 1000
ORDER BY 
    A.ca_state, D.cd_gender;
