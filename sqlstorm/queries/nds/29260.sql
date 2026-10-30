
WITH SplitAddress AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        ca_state,
        ca_zip,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_city, ca_state, ca_zip)) AS full_address,
        TRIM(REGEXP_REPLACE(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_city, ca_state, ca_zip), '[^A-Za-z0-9 ]', '')) AS sanitized_address
    FROM 
        customer_address
),
AddressLength AS (
    SELECT 
        ca_address_sk,
        LENGTH(sanitized_address) AS address_length
    FROM 
        SplitAddress
),
AddressStats AS (
    SELECT 
        MIN(address_length) AS min_length,
        MAX(address_length) AS max_length,
        AVG(address_length) AS avg_length,
        COUNT(*) AS total_addresses
    FROM 
        AddressLength
)
SELECT 
    s.ca_address_sk,
    s.full_address,
    s.sanitized_address,
    l.address_length,
    a.min_length,
    a.max_length,
    a.avg_length,
    a.total_addresses
FROM 
    SplitAddress s
JOIN 
    AddressLength l ON s.ca_address_sk = l.ca_address_sk
CROSS JOIN 
    AddressStats a
ORDER BY 
    l.address_length DESC
LIMIT 10;
