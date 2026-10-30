
WITH string_benchmarks AS (
    SELECT
        ca.ca_address_id,
        ca.ca_street_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state) AS full_address,
        LENGTH(ca.ca_street_name) AS street_name_length,
        LENGTH(CONCAT(ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state)) AS full_address_length,
        REGEXP_REPLACE(ca.ca_street_name, '[^a-zA-Z0-9 ]', '') AS cleaned_street_name,
        UPPER(ca.ca_street_name) AS upper_street_name,
        LOWER(ca.ca_street_name) AS lower_street_name
    FROM
        customer_address ca
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M'
),
aggregated_benchmarks AS (
    SELECT
        COUNT(*) AS address_count,
        AVG(street_name_length) AS avg_street_name_length,
        AVG(full_address_length) AS avg_full_address_length
    FROM
        string_benchmarks
)
SELECT
    sb.ca_address_id,
    sb.ca_street_name,
    sb.full_address,
    ab.address_count,
    ab.avg_street_name_length,
    ab.avg_full_address_length
FROM
    string_benchmarks sb
CROSS JOIN
    aggregated_benchmarks ab
ORDER BY
    sb.full_address_length DESC;
