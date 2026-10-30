
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(ca_address_sk) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsStats AS (
    SELECT 
        cd_gender,
        COUNT(cd_demo_sk) AS total_demographics,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateStats AS (
    SELECT 
        d_year,
        COUNT(d_date_sk) AS total_days,
        SUM(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS total_holidays
    FROM 
        date_dim
    GROUP BY 
        d_year
),
AllStats AS (
    SELECT 
        a.ca_state,
        a.total_addresses,
        a.unique_cities,
        a.avg_street_length,
        d.cd_gender,
        d.total_demographics,
        d.avg_purchase_estimate,
        d.max_dependents,
        date.d_year,
        date.total_days,
        date.total_holidays
    FROM 
        AddressStats a
    INNER JOIN 
        DemographicsStats d ON a.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = (SELECT MIN(ca_address_sk) FROM customer_address))
    CROSS JOIN 
        DateStats date
)
SELECT 
    CONCAT('State: ', ca_state, ' | Total Addresses: ', total_addresses, ' | Unique Cities: ', unique_cities, 
           ' | Avg Street Length: ', avg_street_length, ' | Gender: ', cd_gender, 
           ' | Total Demographics: ', total_demographics, ' | Avg Purchase Estimate: ', avg_purchase_estimate,
           ' | Max Dependents: ', max_dependents, ' | Year: ', d_year, 
           ' | Total Days: ', total_days, ' | Total Holidays: ', total_holidays) AS BenchmarkedStats
FROM 
    AllStats
ORDER BY 
    d_year DESC, total_addresses DESC;
