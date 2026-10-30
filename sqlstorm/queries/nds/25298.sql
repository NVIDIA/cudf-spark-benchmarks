
WITH AddressParts AS (
    SELECT 
        ca_address_sk, 
        TRIM(BOTH ' ' FROM REGEXP_REPLACE(ca_street_name, '[^a-zA-Z0-9\s]', '')) AS clean_street_name,
        TRIM(BOTH ' ' FROM REGEXP_REPLACE(ca_street_type, '[^a-zA-Z]', '')) AS clean_street_type,
        TRIM(BOTH ' ' FROM REGEXP_REPLACE(ca_city, '[^a-zA-Z\s]', '')) AS clean_city,
        TRIM(BOTH ' ' FROM REGEXP_REPLACE(ca_state, '[^a-zA-Z]', '')) AS clean_state,
        TRIM(BOTH ' ' FROM REGEXP_REPLACE(ca_zip, '[^0-9]', '')) AS clean_zip
    FROM customer_address
),
DistinctAddresses AS (
    SELECT DISTINCT
        clean_street_name,
        clean_street_type,
        clean_city,
        clean_state,
        clean_zip
    FROM AddressParts
),
AddressCount AS (
    SELECT 
        clean_city,
        clean_state,
        COUNT(*) AS address_count
    FROM DistinctAddresses
    GROUP BY clean_city, clean_state
)
SELECT 
    clean_city AS City,
    clean_state AS State,
    address_count AS TotalDistinctAddresses
FROM AddressCount
WHERE address_count > 5
ORDER BY address_count DESC;
