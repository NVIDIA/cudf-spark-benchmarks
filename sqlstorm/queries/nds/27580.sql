
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        SUM(LENGTH(ca_street_name)) AS total_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsStats AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_credit_rating) AS highest_credit_rating,
        MIN(cd_dep_count) AS min_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.unique_cities,
    a.total_street_name_length,
    d.cd_gender,
    d.avg_purchase_estimate,
    d.highest_credit_rating,
    d.min_dependents
FROM 
    AddressStats a
JOIN 
    DemographicsStats d ON a.total_addresses > 100
ORDER BY 
    a.total_addresses DESC, 
    d.avg_purchase_estimate DESC
LIMIT 10;
