
WITH  AddressParts AS (
    SELECT 
        ca_address_sk, 
        ca_street_number, 
        ca_street_name, 
        ca_street_type, 
        ca_city, 
        ca_state, 
        ca_zip, 
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS rn
    FROM customer_address
),
CombinedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        rn
    FROM AddressParts
)
SELECT 
    ca_city,
    COUNT(DISTINCT full_address) AS unique_addresses,
    MAX(ca_zip) AS latest_zip_code,
    STRING_AGG(DISTINCT CONCAT(full_address, ' (', ca_state, ')'), '; ') AS detailed_addresses
FROM CombinedAddresses
GROUP BY ca_city
HAVING COUNT(DISTINCT full_address) > 5
ORDER BY unique_addresses DESC;
