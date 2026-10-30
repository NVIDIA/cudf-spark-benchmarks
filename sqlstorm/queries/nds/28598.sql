
WITH string_benchmarks AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        LENGTH(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)) AS address_length,
        UPPER(ca.ca_city) AS city_upper,
        LOWER(ca.ca_street_name) AS street_name_lower,
        REPLACE(ca.ca_zip, '-', '') AS zip_cleaned
    FROM customer_address ca
    WHERE ca.ca_state = 'CA'
),
string_statistics AS (
    SELECT 
        COUNT(*) AS total_addresses,
        AVG(address_length) AS avg_address_length,
        COUNT(DISTINCT city_upper) AS unique_cities,
        COUNT(DISTINCT street_name_lower) AS unique_streets,
        SUM(CASE WHEN zip_cleaned = '' THEN 1 ELSE 0 END) AS missing_zips
    FROM string_benchmarks
)
SELECT 
    total_addresses,
    avg_address_length,
    unique_cities,
    unique_streets,
    missing_zips,
    (SELECT COUNT(*) FROM customer_demographics) AS total_demographics,
    (SELECT COUNT(*) FROM customer) AS total_customers
FROM string_statistics;
