
WITH AddressStats AS (
    SELECT 
        ca_city,
        COUNT(*) AS city_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd_demo_sk) AS unique_demographics
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
FullStats AS (
    SELECT 
        a.ca_city,
        a.city_count,
        a.avg_street_name_length,
        a.max_street_name_length,
        a.min_street_name_length,
        d.gender_count,
        d.avg_purchase_estimate,
        d.unique_demographics
    FROM 
        AddressStats a
    JOIN 
        DemographicStats d ON d.gender_count > 100
)
SELECT 
    fs.ca_city,
    fs.city_count,
    fs.avg_street_name_length,
    fs.max_street_name_length,
    fs.min_street_name_length,
    fs.gender_count,
    fs.avg_purchase_estimate,
    fs.unique_demographics,
    CONCAT('City: ', fs.ca_city, ', Count: ', fs.city_count, ', Avg Street Name Length: ', ROUND(fs.avg_street_name_length, 2), ', Gender Count: ', fs.gender_count) AS detailed_info
FROM 
    FullStats fs
WHERE 
    fs.city_count > 50
ORDER BY 
    fs.city_count DESC;
