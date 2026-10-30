
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city IS NOT NULL AND ca.ca_state IS NOT NULL
),
DistinctCities AS (
    SELECT DISTINCT 
        ca_city,
        ca_state,
        COUNT(*) OVER (PARTITION BY ca_city, ca_state) AS city_count
    FROM customer_address
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    dc.city_count,
    dc.ca_city,
    dc.ca_state,
    dc.city_count * 100.0 / SUM(dc.city_count) OVER () AS city_percentage
FROM CustomerInfo ci
JOIN DistinctCities dc ON ci.ca_city = dc.ca_city AND ci.ca_state = dc.ca_state
WHERE ci.rn = 1 AND ci.cd_gender = 'F'
ORDER BY city_percentage DESC, ci.full_name
LIMIT 50;
