
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(CAST(LENGTH(ca_street_name) AS FLOAT)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(CAST(cd_dep_count AS FLOAT)) AS avg_dep_count,
        AVG(CAST(cd_dep_college_count AS FLOAT)) AS avg_college_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
CombinedStats AS (
    SELECT 
        a.ca_state,
        a.address_count,
        a.max_street_name_length,
        a.min_street_name_length,
        a.avg_street_name_length,
        d.cd_gender,
        d.demographic_count,
        d.avg_dep_count,
        d.avg_college_count
    FROM 
        AddressStats a
    JOIN 
        DemographicStats d ON a.address_count > d.demographic_count
)
SELECT 
    ca_state,
    cd_gender,
    address_count,
    max_street_name_length,
    min_street_name_length,
    avg_street_name_length,
    demographic_count,
    avg_dep_count,
    avg_college_count
FROM 
    CombinedStats
ORDER BY 
    ca_state, cd_gender;
