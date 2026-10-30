
WITH AddressStats AS (
    SELECT
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        SUM(LENGTH(ca_street_number) + LENGTH(ca_street_name) + LENGTH(ca_street_type) + 
            LENGTH(ca_suite_number) + LENGTH(ca_city) + LENGTH(ca_zip) + LENGTH(ca_country)) AS total_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
FinalStats AS (
    SELECT
        a.ca_state,
        a.unique_addresses,
        a.total_length,
        a.avg_street_name_length,
        d.cd_gender,
        d.customer_count,
        d.avg_purchase_estimate,
        d.max_dependents
    FROM
        AddressStats a
    FULL OUTER JOIN 
        DemographicStats d ON a.ca_state IS NOT NULL OR d.cd_gender IS NOT NULL
)
SELECT 
    *,
    CONCAT('State: ', ca_state, ' | Gender: ', cd_gender) AS combined_info,
    ROUND(COALESCE(total_length, 0) / NULLIF(unique_addresses, 0), 2) AS avg_address_length_per_state
FROM 
    FinalStats
ORDER BY 
    ca_state, cd_gender;
