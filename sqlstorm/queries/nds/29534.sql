
WITH  address_parts AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_suite_number,
        ca_city,
        ca_county,
        ca_state,
        ca_zip,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS part_row
    FROM customer_address
),
address_composite AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(', ', 
            NULLIF(ca_street_number, ''), 
            NULLIF(ca_street_name, ''), 
            NULLIF(ca_street_type, ''), 
            NULLIF(ca_suite_number, ''), 
            NULLIF(ca_city, ''), 
            NULLIF(ca_county, ''), 
            NULLIF(ca_state, ''), 
            NULLIF(ca_zip, ''), 
            NULLIF(ca_country, '')
        ) AS full_address,
        part_row
    FROM address_parts
)
SELECT 
    full_address,
    part_row,
    COUNT(*) OVER (PARTITION BY full_address) AS address_count
FROM address_composite
WHERE full_address IS NOT NULL 
ORDER BY address_count DESC, full_address
LIMIT 100;
