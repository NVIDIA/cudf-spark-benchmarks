
WITH AddressStats AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        SUM(CASE 
            WHEN ca_street_type LIKE '%Road%' THEN 1 
            ELSE 0 
        END) AS road_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
), 
DemographicStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    a.road_count,
    d.cd_gender,
    d.cd_marital_status,
    d.demographic_count,
    d.avg_purchase_estimate
FROM 
    AddressStats a
JOIN 
    DemographicStats d ON (a.address_count > 100 AND d.demographic_count > 50)
ORDER BY 
    a.ca_state, a.ca_city, d.cd_gender, d.cd_marital_status;
