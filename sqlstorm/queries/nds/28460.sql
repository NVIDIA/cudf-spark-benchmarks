
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DistinctCities AS (
    SELECT DISTINCT ca_city FROM customer_address
),
CityBenches AS (
    SELECT 
        ct.full_name,
        ct.cd_gender,
        COUNT(*) AS city_count
    FROM CustomerDetails AS ct
    JOIN DistinctCities AS dc ON ct.ca_city = dc.ca_city
    GROUP BY ct.full_name, ct.cd_gender
    HAVING COUNT(*) > 1
),
StringBenchmarks AS (
    SELECT 
        full_name,
        cd_gender,
        LENGTH(full_name) AS name_length,
        LENGTH(cd_gender) AS gender_length,
        city_count
    FROM CityBenches
)
SELECT 
    MIN(name_length) AS min_name_length,
    MAX(name_length) AS max_name_length,
    AVG(name_length) AS avg_name_length,
    MIN(gender_length) AS min_gender_length,
    MAX(gender_length) AS max_gender_length,
    AVG(gender_length) AS avg_gender_length,
    SUM(city_count) AS total_city_count
FROM StringBenchmarks;
