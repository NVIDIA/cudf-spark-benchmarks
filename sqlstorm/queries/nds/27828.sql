
WITH ProcessedAddresses AS (
    SELECT 
        UPPER(ca_street_name) AS street_name_upper,
        TRIM(ca_city) AS city_trimmed,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_city) AS full_address,
        SUBSTRING(ca_zip, 1, 5) AS zip_prefix,
        LENGTH(ca_country) AS country_length,
        COUNT(*) OVER () AS total_addresses
    FROM 
        customer_address
),
AddressStats AS (
    SELECT 
        COUNT(DISTINCT street_name_upper) AS unique_street_names,
        COUNT(DISTINCT city_trimmed) AS unique_cities,
        AVG(country_length) AS avg_country_length,
        MAX(zip_prefix) AS max_zip_prefix
    FROM 
        ProcessedAddresses
)
SELECT 
    a.full_address,
    a.street_name_upper,
    a.city_trimmed,
    a.zip_prefix,
    a.total_addresses,
    s.unique_street_names,
    s.unique_cities,
    s.avg_country_length,
    s.max_zip_prefix
FROM 
    ProcessedAddresses a
JOIN 
    AddressStats s ON 1=1
WHERE 
    a.total_addresses > 1000
GROUP BY 
    a.full_address,
    a.street_name_upper,
    a.city_trimmed,
    a.zip_prefix,
    a.total_addresses,
    s.unique_street_names,
    s.unique_cities,
    s.avg_country_length,
    s.max_zip_prefix
ORDER BY 
    a.city_trimmed ASC, a.street_name_upper DESC
LIMIT 50;
