
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS unique_demographics,
        COUNT(*) AS total_demographics,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependency_count,
        MIN(cd_dep_count) AS min_dependency_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
CombinedStats AS (
    SELECT 
        a.ca_state,
        a.unique_addresses,
        a.total_addresses,
        d.cd_gender,
        d.unique_demographics,
        d.total_demographics,
        a.avg_street_name_length,
        a.max_street_name_length,
        a.min_street_name_length,
        d.avg_purchase_estimate,
        d.max_dependency_count,
        d.min_dependency_count
    FROM 
        AddressStats a
    JOIN 
        DemographicsStats d ON a.ca_state IS NOT NULL
)
SELECT 
    ca_state,
    unique_addresses,
    total_addresses,
    cd_gender,
    unique_demographics,
    total_demographics,
    avg_street_name_length,
    max_street_name_length,
    min_street_name_length,
    avg_purchase_estimate,
    max_dependency_count,
    min_dependency_count
FROM 
    CombinedStats
ORDER BY 
    unique_addresses DESC, 
    total_addresses DESC, 
    cd_gender;
