
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER(PARTITION BY ca_city ORDER BY ca_city) AS city_rank
    FROM customer_address
    WHERE ca_country = 'USA'
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(cd_demo_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender
),
DateInfo AS (
    SELECT 
        d_year,
        d_month_seq,
        AVG(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS avg_holiday_sales,
        COUNT(d_date) AS total_days
    FROM date_dim
    GROUP BY d_year, d_month_seq
)
SELECT 
    A.full_address,
    A.ca_city,
    A.ca_state,
    A.ca_country,
    D.cd_gender,
    D.demographic_count,
    D.avg_purchase_estimate,
    I.d_year,
    I.d_month_seq,
    I.avg_holiday_sales,
    I.total_days
FROM AddressDetails A
JOIN DemographicStats D ON A.city_rank = D.demographic_count
JOIN DateInfo I ON D.demographic_count > 10
ORDER BY A.ca_city, D.cd_gender, I.d_year;
