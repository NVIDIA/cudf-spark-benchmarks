
WITH processed_addresses AS (
    SELECT
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS address_location,
        LOWER(ca_country) AS country_lowercase
    FROM
        customer_address
),
demographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CONCAT(cd_gender, '-', cd_marital_status) AS gender_marital,
        COUNT(*) OVER(PARTITION BY cd_gender) AS gender_count,
        COUNT(*) OVER(PARTITION BY cd_marital_status) AS marital_count
    FROM
        customer_demographics
)
SELECT
    pa.full_address,
    pa.address_location,
    pa.country_lowercase,
    d.gender_marital,
    d.gender_count,
    d.marital_count
FROM
    processed_addresses pa
JOIN
    demographics d ON pa.ca_address_sk = d.cd_demo_sk
WHERE
    pa.country_lowercase LIKE '%usa%'
ORDER BY
    pa.full_address;
