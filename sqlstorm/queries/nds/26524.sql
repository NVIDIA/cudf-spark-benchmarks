
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_city) AS unique_cities, 
        COUNT(DISTINCT ca_zip) AS unique_zips, 
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
CombinedStats AS (
    SELECT 
        a.ca_state,
        a.unique_cities,
        a.unique_zips,
        a.avg_street_name_length,
        d.cd_gender,
        d.total_customers,
        d.avg_purchase_estimate,
        d.max_dependents
    FROM 
        AddressStats a
    CROSS JOIN 
        DemographicsStats d
)
SELECT 
    ca_state,
    unique_cities,
    unique_zips,
    avg_street_name_length,
    cd_gender,
    total_customers,
    avg_purchase_estimate,
    max_dependents
FROM 
    CombinedStats
WHERE 
    unique_cities > 10 AND 
    avg_purchase_estimate > 500
ORDER BY 
    ca_state, cd_gender;
