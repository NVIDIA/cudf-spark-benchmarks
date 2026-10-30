
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_demographics,
        AVG(cd_dep_count) AS avg_dependent_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimates
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.unique_cities,
    a.max_street_name_length,
    a.min_street_name_length,
    a.avg_street_name_length,
    d.cd_gender,
    d.total_demographics,
    d.avg_dependent_count,
    d.total_purchase_estimates
FROM 
    AddressSummary a
JOIN 
    DemographicSummary d ON 1=1
ORDER BY 
    a.total_addresses DESC, d.total_demographics DESC;
