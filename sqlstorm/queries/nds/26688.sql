
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank,
        LENGTH(ca_street_name) AS street_name_length,
        REPLACE(ca_street_name, ' ', '') AS street_name_no_spaces,
        UPPER(ca_city) AS city_uppercase,
        CONCAT(ca_street_number, ' ', ca_street_name) AS full_address
    FROM 
        customer_address
),
CityStatistics AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_city) AS total_cities,
        AVG(street_name_length) AS avg_street_name_length
    FROM 
        RankedAddresses
    GROUP BY 
        ca_state
)
SELECT 
    ra.ca_address_sk,
    ra.full_address,
    ra.city_uppercase,
    cs.total_cities,
    cs.avg_street_name_length
FROM 
    RankedAddresses ra
JOIN 
    CityStatistics cs ON ra.ca_state = cs.ca_state
WHERE 
    ra.city_rank <= 5
ORDER BY 
    cs.total_cities DESC, ra.city_uppercase;
