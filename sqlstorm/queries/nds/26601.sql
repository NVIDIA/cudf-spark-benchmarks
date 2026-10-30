
WITH address_stats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_suite_number)) AS longest_suite_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demo_stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependent_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
date_stats AS (
    SELECT 
        d_year,
        COUNT(*) AS total_dates,
        AVG(DATE_PART('day', d_date)) AS avg_days_in_month,
        SUM(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS total_holidays
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.unique_cities,
    a.avg_street_name_length,
    a.longest_suite_length,
    d.cd_gender,
    d.total_customers,
    d.avg_dependent_count,
    d.total_purchase_estimate,
    d.highest_credit_rating,
    dt.d_year,
    dt.total_dates,
    dt.avg_days_in_month,
    dt.total_holidays
FROM 
    address_stats a
JOIN 
    demo_stats d ON a.total_addresses > 100
JOIN 
    date_stats dt ON dt.total_dates > 2000
ORDER BY 
    a.ca_state, d.cd_gender, dt.d_year;
