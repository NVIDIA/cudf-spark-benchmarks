
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_city)) AS max_city_length,
        MIN(LENGTH(ca_city)) AS min_city_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_demographics,
        AVG(cd_dep_count) AS avg_dep_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateStats AS (
    SELECT 
        d_year,
        COUNT(*) AS total_dates,
        MAX(DATE_PART('day', d_date)) AS max_day,
        MIN(DATE_PART('day', d_date)) AS min_day
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.avg_street_name_length,
    a.max_city_length,
    a.min_city_length,
    d.cd_gender,
    d.total_demographics,
    d.avg_dep_count,
    d.max_purchase_estimate,
    date.d_year,
    date.total_dates,
    date.max_day,
    date.min_day
FROM 
    AddressStats a
JOIN 
    DemographicsStats d ON a.total_addresses > 100
JOIN 
    DateStats date ON date.total_dates > 500
ORDER BY 
    a.ca_state, d.cd_gender, date.d_year;
