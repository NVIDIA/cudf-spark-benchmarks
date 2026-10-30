
WITH processed_data AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        LOWER(ca.ca_street_name) AS normalized_street_name,
        REGEXP_REPLACE(ca.ca_street_name, '[^a-zA-Z0-9 ]', '') AS clean_street_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state) AS full_address,
        REPLACE(REPLACE(ca.ca_zip, '-', ''), ' ', '') AS clean_zip
    FROM
        customer_address ca
    WHERE
        ca.ca_city IS NOT NULL
),
address_stats AS (
    SELECT
        ca_state,
        COUNT(*) AS address_count,
        COUNT(DISTINCT full_address) AS unique_address_count,
        AVG(LENGTH(normalized_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN CHAR_LENGTH(clean_zip) = 5 THEN 1 ELSE 0 END) AS valid_zip_count,
        SUM(CASE WHEN CHAR_LENGTH(clean_zip) < 5 THEN 1 ELSE 0 END) AS invalid_zip_count
    FROM
        processed_data
    GROUP BY
        ca_state
)
SELECT
    a.ca_state,
    a.address_count,
    a.unique_address_count,
    a.avg_street_name_length,
    a.valid_zip_count,
    a.invalid_zip_count,
    RANK() OVER (ORDER BY a.address_count DESC) AS address_rank
FROM
    address_stats a
ORDER BY
    a.address_count DESC
LIMIT 10;
