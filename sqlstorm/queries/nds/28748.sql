
WITH AddressAnalysis AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL 
        AND ca_state IS NOT NULL
    GROUP BY 
        ca_city,
        ca_state
),
DemographicAnalysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_gender IS NOT NULL 
        AND cd_marital_status IS NOT NULL
    GROUP BY 
        cd_gender,
        cd_marital_status
),
DateAnalysis AS (
    SELECT 
        d_year,
        COUNT(*) AS total_dates,
        COUNT(DISTINCT d_date) AS unique_dates
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    d.cd_gender,
    d.cd_marital_status,
    d.demographic_count,
    d.avg_purchase_estimate,
    d.max_purchase_estimate,
    date_analysis.d_year,
    date_analysis.total_dates,
    date_analysis.unique_dates
FROM 
    AddressAnalysis a
JOIN 
    DemographicAnalysis d ON a.address_count > 10
CROSS JOIN 
    DateAnalysis date_analysis
ORDER BY 
    a.address_count DESC, 
    d.demographic_count DESC;
