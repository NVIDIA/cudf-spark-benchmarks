WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        SUM(LENGTH(ca_street_name)) AS total_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate
    FROM 
        customer_demographics 
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
DemographicIncome AS (
    SELECT 
        hd_income_band_sk,
        COUNT(DISTINCT hd_demo_sk) AS total_households,
        AVG(hd_vehicle_count) AS avg_vehicle_count,
        MIN(hd_vehicle_count) AS min_vehicle_count,
        MAX(hd_vehicle_count) AS max_vehicle_count
    FROM 
        household_demographics
    GROUP BY 
        hd_income_band_sk
),
DateRange AS (
    SELECT 
        MIN(d_date) AS start_date,
        MAX(d_date) AS end_date,
        COUNT(*) AS total_days
    FROM 
        date_dim
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.total_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    c.cd_gender,
    c.total_customers,
    c.avg_dependents,
    c.avg_purchase_estimate,
    c.max_purchase_estimate,
    c.min_purchase_estimate,
    d.hd_income_band_sk,
    d.total_households,
    d.avg_vehicle_count,
    d.min_vehicle_count,
    d.max_vehicle_count,
    date_range.start_date,
    date_range.end_date,
    date_range.total_days
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.ca_state = 'CA' 
JOIN 
    DemographicIncome d ON d.hd_income_band_sk IS NOT NULL
CROSS JOIN 
    DateRange date_range
ORDER BY 
    a.unique_addresses DESC, 
    c.total_customers DESC;