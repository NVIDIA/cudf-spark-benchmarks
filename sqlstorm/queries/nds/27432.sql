
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        REPLACE(ca_city, 'City', '') AS city_name,
        UPPER(ca_state) AS state_code,
        LEFT(ca_zip, 5) AS zip_prefix
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
address_summary AS (
    SELECT 
        state_code,
        COUNT(*) AS address_count,
        COUNT(DISTINCT city_name) AS distinct_cities,
        MAX(LENGTH(full_address)) AS max_address_length
    FROM 
        processed_addresses
    GROUP BY 
        state_code
)
SELECT 
    state_code,
    address_count,
    distinct_cities,
    max_address_length,
    CASE 
        WHEN address_count > 100 THEN 'High Density'
        WHEN address_count BETWEEN 50 AND 100 THEN 'Medium Density'
        ELSE 'Low Density'
    END AS density_category
FROM 
    address_summary
ORDER BY 
    address_count DESC;
