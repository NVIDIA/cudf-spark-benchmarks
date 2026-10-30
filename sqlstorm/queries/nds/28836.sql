
WITH AddressComponents AS (
    SELECT ca_address_sk,
           CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country) AS full_address,
           LENGTH(CONCAT_WS(' ', ca_street_number, ca_street_name)) AS address_length,
           LOWER(ca_city) AS city_lower,
           UPPER(ca_state) AS state_upper
    FROM customer_address
),
BenchmarkedDemographics AS (
    SELECT cd_demo_sk,
           cd_gender,
           cd_marital_status,
           cd_education_status,
           REGEXP_REPLACE(CAST(cd_purchase_estimate AS STRING), '[^0-9]', '') AS purchase_estimate_clean,
           cd_credit_rating,
           cd_dep_count,
           cd_dep_employed_count
    FROM customer_demographics
),
DateStats AS (
    SELECT d_year,
           COUNT(*) AS total_days,
           AVG(d_dom) AS avg_day_of_month,
           STRING_AGG(d_day_name, ', ') AS all_days_names
    FROM date_dim
    GROUP BY d_year
),
AddressCount AS (
    SELECT ca_city,
           COUNT(*) AS city_address_count
    FROM customer_address
    GROUP BY ca_city
    HAVING COUNT(*) > 10
)
SELECT ac.full_address,
       bd.cd_gender,
       ds.d_year,
       ds.total_days,
       a_count.city_address_count,
       bd.purchase_estimate_clean,
       ds.all_days_names
FROM AddressComponents ac
JOIN BenchmarkedDemographics bd ON ac.ca_address_sk = bd.cd_demo_sk
JOIN DateStats ds ON ds.d_year = EXTRACT(YEAR FROM CAST('2002-10-01' AS DATE))
JOIN AddressCount a_count ON a_count.ca_city = ac.city_lower
ORDER BY a_count.city_address_count DESC, ac.full_address;
