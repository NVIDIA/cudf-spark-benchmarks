
WITH CustomerAddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(ca_address_id) AS total_addresses,
        SUM(LENGTH(ca_street_name)) AS total_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographicsStats AS (
    SELECT 
        cd_marital_status,
        COUNT(DISTINCT cd_demo_sk) AS unique_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS total_dependents_employed
    FROM 
        customer_demographics
    GROUP BY 
        cd_marital_status
),
DateStats AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_id) AS unique_days,
        AVG(d_dom) AS avg_day_of_month,
        COUNT(CASE WHEN d_holiday = 'Y' THEN 1 END) AS total_holidays
    FROM 
        date_dim
    GROUP BY 
        d_year
),
CombinedStats AS (
    SELECT 
        ca.ca_state,
        ca.unique_addresses,
        ca.total_addresses,
        ca.total_street_name_length,
        ca.avg_street_name_length,
        cd.cd_marital_status,
        cd.unique_customers,
        cd.avg_purchase_estimate,
        cd.total_dependents,
        cd.total_dependents_employed,
        ds.d_year,
        ds.unique_days,
        ds.avg_day_of_month,
        ds.total_holidays
    FROM 
        CustomerAddressStats ca
    JOIN 
        CustomerDemographicsStats cd ON 1=1
    JOIN 
        DateStats ds ON 1=1
)
SELECT 
    ca_state, 
    unique_addresses, 
    total_addresses, 
    total_street_name_length, 
    avg_street_name_length,
    cd_marital_status,
    unique_customers,
    avg_purchase_estimate,
    total_dependents,
    total_dependents_employed,
    d_year,
    unique_days,
    avg_day_of_month,
    total_holidays
FROM 
    CombinedStats
ORDER BY 
    ca_state, cd_marital_status, d_year;
