
WITH string_benchmark AS (
    SELECT 
        ca_address_id,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        LENGTH(TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type))) AS address_length,
        REGEXP_REPLACE(ca_city, '[^A-Za-z ]', '') AS cleaned_city,
        UPPER(ca_state) AS upper_state,
        REPLACE(ca_zip, '-', '') AS sanitized_zip
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
address_statistics AS (
    SELECT 
        AVG(LENGTH(full_address)) AS avg_length,
        COUNT(DISTINCT cleaned_city) AS unique_cities,
        COUNT(*) AS total_addresses
    FROM 
        string_benchmark
)
SELECT 
    avg_length,
    unique_cities,
    total_addresses,
    ROUND((1234567890 * RANDOM()), 2) AS random_value
FROM 
    address_statistics
WHERE 
    avg_length > 50
ORDER BY 
    unique_cities DESC
LIMIT 10;
