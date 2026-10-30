
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        COUNT(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS unique_streets
    FROM 
        customer_address 
    GROUP BY 
        ca_state
),
gender_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics 
    GROUP BY 
        cd_gender
),
date_summary AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_id) AS active_days,
        AVG(d_dom) AS avg_day_of_month,
        SUM(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_count
    FROM 
        date_dim 
    GROUP BY 
        d_year
),
combined_summary AS (
    SELECT 
        a.ca_state,
        a.unique_addresses,
        a.unique_cities,
        a.unique_streets,
        g.cd_gender,
        g.demographic_count,
        g.total_dependents,
        g.avg_purchase_estimate,
        d.d_year,
        d.active_days,
        d.avg_day_of_month,
        d.holiday_count
    FROM 
        address_summary a
    JOIN 
        gender_summary g ON g.demographic_count >= 100
    JOIN 
        date_summary d ON d.active_days > 30
)
SELECT 
    CONCAT('In ', ca_state, ', there are ', unique_addresses, ' unique addresses among ', unique_cities, ' cities, with ', unique_streets, ' unique street combinations. ',
    'The demographic analysis shows ', demographic_count, ' individuals of gender ', cd_gender, ' with ', total_dependents, ' dependents, averaging a purchase estimate of $', ROUND(avg_purchase_estimate::numeric, 2), '. ',
    'In the year ', d_year, ', there were ', active_days, ' active days with an average day of the month being ', avg_day_of_month, ' and ', holiday_count, ' holidays recorded.') AS benchmark_report
FROM 
    combined_summary
ORDER BY 
    unique_addresses DESC
LIMIT 10;
