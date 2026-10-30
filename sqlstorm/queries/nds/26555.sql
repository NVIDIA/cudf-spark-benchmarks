
WITH StringBenchmark AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip)) AS address_length,
        REGEXP_REPLACE(ca_street_name, '[^a-zA-Z0-9 ]', '') AS sanitized_street_name,
        UPPER(ca_city) AS upper_city,
        LOWER(ca_suite_number) AS lower_suite_number,
        TRIM(ca_country) AS trimmed_country
    FROM 
        customer_address
),
AggregatedResults AS (
    SELECT 
        AVG(address_length) AS avg_address_length,
        COUNT(DISTINCT sanitized_street_name) AS unique_street_names,
        COUNT(DISTINCT upper_city) AS unique_upper_cities,
        COUNT(DISTINCT lower_suite_number) AS unique_lower_suite_numbers,
        COUNT(DISTINCT trimmed_country) AS unique_trimmed_countries
    FROM 
        StringBenchmark
)
SELECT 
    avg_address_length,
    unique_street_names,
    unique_upper_cities,
    unique_lower_suite_numbers,
    unique_trimmed_countries
FROM 
    AggregatedResults;
