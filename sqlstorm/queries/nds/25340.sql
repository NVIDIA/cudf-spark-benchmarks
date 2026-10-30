
WITH AddressAnalysis AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND 
        ca_state IS NOT NULL
    GROUP BY 
        ca_city, ca_state
),
DemographicsAnalysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT cd_demo_sk) AS count_demo,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MIN(cd_dep_college_count) AS min_college_dep_count,
        MAX(cd_dep_college_count) AS max_college_dep_count
    FROM 
        customer_demographics
    WHERE 
        cd_gender IN ('M', 'F')
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.unique_addresses,
    a.avg_street_name_length,
    a.max_street_name_length,
    d.cd_gender,
    d.cd_marital_status,
    d.count_demo,
    d.avg_purchase_estimate,
    d.min_college_dep_count,
    d.max_college_dep_count
FROM 
    AddressAnalysis a
JOIN 
    DemographicsAnalysis d 
ON 
    a.ca_city LIKE CONCAT('%', d.cd_gender, '%')
ORDER BY 
    a.ca_state, d.cd_marital_status;
