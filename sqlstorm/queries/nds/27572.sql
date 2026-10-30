
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_number) || ' ' || 
        TRIM(ca_street_name) || ' ' || 
        TRIM(ca_street_type) || ' ' || 
        COALESCE(TRIM(ca_suite_number), '') || 
        ', ' || TRIM(ca_city) || ', ' || 
        TRIM(ca_state) || ' ' || 
        TRIM(ca_zip) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS address_rank
    FROM 
        customer_address
),
DistinctAddresses AS (
    SELECT DISTINCT 
        full_address
    FROM 
        RankedAddresses
    WHERE 
        address_rank = 1
),
AddressStatistics AS (
    SELECT 
        SUBSTRING(full_address FROM POSITION(',' IN full_address) + 1) AS region,
        COUNT(*) AS address_count,
        MAX(LENGTH(full_address)) AS max_address_length,
        MIN(LENGTH(full_address)) AS min_address_length,
        AVG(LENGTH(full_address)) AS avg_address_length
    FROM 
        DistinctAddresses
    GROUP BY 
        region
)
SELECT 
    region, 
    address_count, 
    min_address_length, 
    avg_address_length, 
    max_address_length
FROM 
    AddressStatistics
ORDER BY 
    address_count DESC;
