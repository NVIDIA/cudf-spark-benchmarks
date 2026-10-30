
WITH String_Benchmark AS (
    SELECT 
        ca_address_sk,
        LOWER(ca_street_name) AS lowercase_street_name,
        UPPER(ca_city) AS uppercase_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length,
        REGEXP_REPLACE(ca_zip, '[^0-9]', '') AS cleaned_zip,
        SUBSTRING(ca_country FROM 1 FOR 3) AS country_code,
        STRING_AGG(CAST(ca_address_id AS STRING), ',') OVER (PARTITION BY ca_state ORDER BY ca_address_sk) AS address_ids
    FROM 
        customer_address
),
Aggregated_Benchmarks AS (
    SELECT 
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT cleaned_zip) AS unique_zip_codes,
        AVG(street_name_length) AS avg_street_name_length,
        AVG(city_length) AS avg_city_length
    FROM 
        String_Benchmark
)
SELECT 
    *,
    CASE 
        WHEN total_addresses > 0 THEN (avg_street_name_length / total_addresses) * 100 
        ELSE 0 
    END AS street_name_length_ratio,
    CASE 
        WHEN unique_zip_codes > 0 THEN (avg_city_length / unique_zip_codes) * 100 
        ELSE 0 
    END AS city_length_ratio
FROM 
    Aggregated_Benchmarks;
