
WITH RankedAddresses AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_suite_number, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_street_name) AS rank
    FROM 
        customer_address
),
FilteredAddresses AS (
    SELECT 
        full_address,
        rank
    FROM 
        RankedAddresses
    WHERE 
        full_address LIKE '%Main%'
),
AddressStats AS (
    SELECT 
        SUBSTRING(full_address, POSITION(',' IN full_address) + 2, LENGTH(full_address)) AS city_state_zip,
        COUNT(*) AS address_count
    FROM 
        FilteredAddresses
    GROUP BY 
        SUBSTRING(full_address, POSITION(',' IN full_address) + 2, LENGTH(full_address))
)
SELECT 
    city_state_zip,
    address_count,
    AVG(LENGTH(full_address)) AS avg_address_length
FROM 
    FilteredAddresses
JOIN 
    AddressStats ON SUBSTRING(full_address, POSITION(',' IN full_address) + 2, LENGTH(full_address)) = city_state_zip
GROUP BY 
    city_state_zip, address_count
ORDER BY 
    city_state_zip;
