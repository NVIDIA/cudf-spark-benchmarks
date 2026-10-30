
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
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
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
StringComparison AS (
    SELECT 
        a.ca_state,
        d.cd_gender,
        a.address_count,
        d.demographic_count,
        CONCAT('State: ', a.ca_state, ', Address Count: ', a.address_count, 
               ' | Gender: ', d.cd_gender, ', Demographic Count: ', d.demographic_count) AS combined_info
    FROM 
        AddressStats a
    JOIN 
        DemographicsStats d ON 1=1
)
SELECT 
    combined_info,
    REPLACE(combined_info, 'Count', 'Total') AS adjusted_info,
    UPPER(combined_info) AS upper_info,
    LOWER(combined_info) AS lower_info
FROM 
    StringComparison
ORDER BY 
    address_count DESC, demographic_count DESC;
