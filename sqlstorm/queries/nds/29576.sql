
WITH processed_addresses AS (
    SELECT
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        UPPER(TRIM(ca_city)) AS city_upper,
        LOWER(TRIM(ca_state)) AS state_lower,
        CONCAT(SUBSTRING(ca_zip, 1, 5), '-', SUBSTRING(ca_zip, 6, 4)) AS formatted_zip
    FROM customer_address
),
address_stats AS (
    SELECT
        city_upper,
        state_lower,
        COUNT(*) AS address_count,
        AVG(LENGTH(full_address)) AS avg_address_length,
        COUNT(DISTINCT formatted_zip) AS unique_zip_count
    FROM processed_addresses
    GROUP BY city_upper, state_lower
)
SELECT
    city_upper,
    state_lower,
    address_count,
    avg_address_length,
    unique_zip_count
FROM address_stats
WHERE address_count > 1
ORDER BY address_count DESC, avg_address_length ASC
LIMIT 10;
