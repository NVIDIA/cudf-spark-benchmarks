
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(CASE WHEN ca_city IS NOT NULL THEN LENGTH(ca_city) ELSE 0 END) AS max_city_length,
        MIN(CASE WHEN ca_city IS NOT NULL THEN LENGTH(ca_city) ELSE 0 END) AS min_city_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_marital_status,
        COUNT(*) AS customer_count,
        SUM(cd_dep_count) AS total_dependencies,
        SUM(cd_dep_college_count) AS total_college_dependencies
    FROM 
        customer_demographics
    GROUP BY 
        cd_marital_status
),
DateStats AS (
    SELECT 
        d_year,
        COUNT(*) AS total_days,
        AVG(EXTRACT(DAY FROM d_date)) AS avg_day_of_month,
        MAX(d_dow) AS max_day_of_week,
        MIN(d_dow) AS min_day_of_week
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    A.ca_state, 
    A.address_count, 
    A.avg_street_name_length, 
    C.cd_marital_status, 
    C.customer_count, 
    C.total_dependencies, 
    D.d_year, 
    D.total_days, 
    D.avg_day_of_month
FROM 
    AddressStats A
JOIN 
    CustomerStats C ON C.customer_count > 1000
JOIN 
    DateStats D ON D.total_days > 365
ORDER BY 
    A.ca_state, 
    C.customer_count DESC, 
    D.d_year;
