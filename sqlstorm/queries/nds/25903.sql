
WITH StringBenchmark AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_city) AS upper_city,
        LOWER(ca_country) AS lower_country,
        REPLACE(ca_street_type, 'St', 'Street') AS full_street_type,
        CONCAT(ca_state, '-', ca_zip) AS state_zip
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
DistinctCounts AS (
    SELECT 
        COUNT(DISTINCT upper_city) AS distinct_cities,
        COUNT(DISTINCT lower_country) AS distinct_countries,
        COUNT(DISTINCT full_street_type) AS distinct_street_types
    FROM 
        StringBenchmark
)
SELECT 
    sb.full_address,
    sb.street_name_length,
    sb.upper_city,
    sb.lower_country,
    sb.full_street_type,
    dc.distinct_cities,
    dc.distinct_countries,
    dc.distinct_street_types
FROM 
    StringBenchmark sb
CROSS JOIN 
    DistinctCounts dc
ORDER BY 
    sb.street_name_length DESC
LIMIT 100;
