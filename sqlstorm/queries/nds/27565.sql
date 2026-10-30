
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        COUNT(DISTINCT ca_city) AS unique_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemoStats AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateStats AS (
    SELECT 
        d_year,
        COUNT(*) AS total_days,
        COUNT(DISTINCT d_month_seq) AS unique_months
    FROM 
        date_dim
    GROUP BY 
        d_year
),
FinalBenchmark AS (
    SELECT 
        a.ca_state AS state,
        a.total_addresses,
        a.avg_street_name_length,
        a.unique_cities,
        c.cd_gender,
        c.avg_purchase_estimate,
        c.total_dependents,
        d.d_year,
        d.total_days,
        d.unique_months
    FROM 
        AddressStats a
    JOIN 
        CustomerDemoStats c ON TRUE
    JOIN 
        DateStats d ON TRUE
)
SELECT 
    state,
    total_addresses,
    avg_street_name_length,
    unique_cities,
    cd_gender,
    avg_purchase_estimate,
    total_dependents,
    d_year,
    total_days,
    unique_months 
FROM 
    FinalBenchmark
ORDER BY 
    state, cd_gender, d_year;
