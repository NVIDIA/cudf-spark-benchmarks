
WITH AddressSummary AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        COUNT(DISTINCT ca_zip) AS unique_zips,
        AVG(COALESCE(LENGTH(ca_street_name), 0)) AS avg_street_name_length,
        SUM(COALESCE(CASE WHEN LENGTH(ca_street_name) > 0 THEN 1 ELSE 0 END, 0)) AS non_empty_street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsSummary AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT cd_demo_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(CASE WHEN cd_marital_status = 'M' THEN 1 END) AS married_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.unique_cities,
    a.unique_zips,
    a.avg_street_name_length,
    a.non_empty_street_names,
    d.cd_gender,
    d.demographic_count,
    d.avg_purchase_estimate,
    d.married_count
FROM 
    AddressSummary a
JOIN 
    DemographicsSummary d ON a.unique_addresses > d.demographic_count
ORDER BY 
    a.ca_state, d.cd_gender;
