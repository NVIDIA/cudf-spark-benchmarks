
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type) AS full_address,
        UPPER(ca_city) AS city_upper,
        LOWER(ca_zip) AS zip_lower
    FROM 
        customer_address
),
DistinctCities AS (
    SELECT DISTINCT city_upper
    FROM AddressParts
),
AddressAggregates AS (
    SELECT 
        ap.city_upper,
        COUNT(DISTINCT ap.ca_address_sk) AS address_count,
        COUNT(DISTINCT LENGTH(ap.full_address)) AS unique_length_count
    FROM 
        AddressParts ap
    JOIN 
        DistinctCities dc ON ap.city_upper = dc.city_upper
    GROUP BY 
        ap.city_upper
)
SELECT 
    a.city_upper,
    a.address_count,
    a.unique_length_count,
    CASE 
        WHEN a.address_count > 100 THEN 'High Density'
        WHEN a.address_count > 50 THEN 'Medium Density'
        ELSE 'Low Density' 
    END AS density_category
FROM 
    AddressAggregates a
ORDER BY 
    a.address_count DESC, a.city_upper;
