
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, ''))) AS full_address,
        ca_city,
        ca_state
    FROM customer_address
),
FilteredAddresses AS (
    SELECT 
        full_address,
        ca_city,
        ca_state,
        LENGTH(full_address) AS address_length,
        REGEXP_REPLACE(full_address, '[^a-zA-Z0-9 ]', '') AS cleaned_address
    FROM AddressParts
    WHERE 
        ca_city IS NOT NULL 
        AND ca_state IN ('CA', 'NY', 'TX')
),
AggregatedAddresses AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        AVG(address_length) AS avg_length,
        MAX(address_length) AS max_length,
        MIN(address_length) AS min_length
    FROM FilteredAddresses
    GROUP BY ca_city, ca_state
)
SELECT 
    ca_city,
    ca_state,
    address_count,
    avg_length,
    max_length,
    min_length,
    CONCAT('Total addresses in ', ca_city, ', ', ca_state, ': ', address_count) AS address_summary
FROM AggregatedAddresses
ORDER BY ca_state, ca_city;
