
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS distinct_address_count,
        SUM(LENGTH(ca_street_name)) AS total_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateSummary AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_id) AS unique_dates,
        COUNT(CASE WHEN d_holiday = 'Y' THEN 1 END) AS holiday_count
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.distinct_address_count,
    a.total_street_name_length,
    d.cd_gender,
    d.avg_purchase_estimate,
    d.demographic_count,
    dt.d_year,
    dt.unique_dates,
    dt.holiday_count
FROM 
    AddressCounts a
JOIN 
    DemographicSummary d ON a.distinct_address_count > 10
JOIN 
    DateSummary dt ON dt.unique_dates > 50
ORDER BY 
    a.ca_state, d.cd_gender;
