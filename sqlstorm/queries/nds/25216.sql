
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip
    FROM 
        customer_address
),
DistinctAddresses AS (
    SELECT DISTINCT
        full_address,
        city,
        state,
        zip
    FROM 
        AddressParts
),
AddressStatistics AS (
    SELECT 
        state,
        COUNT(DISTINCT full_address) AS unique_address_count,
        COUNT(DISTINCT city) AS unique_city_count,
        MAX(LENGTH(full_address)) AS max_address_length
    FROM 
        DistinctAddresses
    GROUP BY 
        state
)
SELECT 
    state, 
    unique_address_count,
    unique_city_count,
    max_address_length,
    CONCAT('State: ', state, ', Unique Addresses: ', unique_address_count, ', Unique Cities: ', unique_city_count, ', Max Address Length: ', max_address_length) AS detailed_info
FROM 
    AddressStatistics
ORDER BY 
    state;
