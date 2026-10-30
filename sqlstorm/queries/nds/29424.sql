
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS distinct_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        AVG(LENGTH(ca_street_type)) AS avg_street_type_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_demographics,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS total_dependents_employed
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
CompositeStats AS (
    SELECT 
        a.ca_state,
        a.total_addresses,
        a.distinct_cities,
        a.avg_street_name_length,
        a.avg_street_type_length,
        d.cd_gender,
        d.total_demographics,
        d.avg_purchase_estimate,
        d.total_dependents,
        d.total_dependents_employed
    FROM 
        AddressStats a
    CROSS JOIN 
        DemographicStats d
)
SELECT 
    cs.ca_state,
    cs.total_addresses,
    cs.distinct_cities,
    cs.avg_street_name_length,
    cs.avg_street_type_length,
    cs.cd_gender,
    cs.total_demographics,
    cs.avg_purchase_estimate,
    cs.total_dependents,
    cs.total_dependents_employed,
    CONCAT(cs.ca_state, ' has ', cs.total_addresses, ' total addresses and the gender stats are for ', cs.cd_gender) AS summary
FROM 
    CompositeStats cs
WHERE 
    cs.total_addresses > 100
ORDER BY 
    cs.total_addresses DESC, cs.cd_gender;
