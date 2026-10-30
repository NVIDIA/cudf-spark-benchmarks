
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN ca_city LIKE '%ville%' THEN 1 ELSE 0 END) AS ville_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
), DemographicsStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), CombinedStats AS (
    SELECT 
        a.ca_state,
        a.unique_addresses,
        a.max_street_name_length,
        a.avg_street_name_length,
        a.ville_count,
        d.cd_gender,
        d.total_customers,
        d.avg_purchase_estimate,
        d.max_dependents
    FROM 
        AddressStats a
    JOIN 
        DemographicsStats d ON a.ca_state IS NOT NULL 
)
SELECT 
    CONCAT(a.ca_state, ' - ', d.cd_gender) AS state_gender,
    a.unique_addresses,
    a.max_street_name_length,
    a.avg_street_name_length,
    a.ville_count,
    d.total_customers,
    d.avg_purchase_estimate,
    d.max_dependents
FROM 
    CombinedStats a
JOIN 
    CombinedStats d ON a.cd_gender = d.cd_gender
ORDER BY 
    a.ca_state, d.cd_gender;
