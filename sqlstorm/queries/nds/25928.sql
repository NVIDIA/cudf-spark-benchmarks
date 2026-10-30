
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY LENGTH(ca_street_name) DESC) as rn
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND 
        ca_state IS NOT NULL AND 
        ca_street_name IS NOT NULL
),
PopularCities AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) as address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, 
        ca_state
    HAVING 
        COUNT(*) > 10
),
FilteredAddresses AS (
    SELECT 
        ra.ca_address_sk,
        ra.ca_city,
        ra.ca_state,
        ra.ca_country
    FROM 
        RankedAddresses ra
    INNER JOIN 
        PopularCities pc ON ra.ca_city = pc.ca_city AND ra.ca_state = pc.ca_state
    WHERE 
        ra.rn = 1
)
SELECT 
    fa.ca_address_sk,
    fa.ca_city,
    fa.ca_state,
    fa.ca_country,
    CONCAT('Address in ', fa.ca_city, ', ', fa.ca_state, ', ', fa.ca_country) AS full_address_description
FROM 
    FilteredAddresses fa
ORDER BY 
    fa.ca_city, 
    fa.ca_state;
