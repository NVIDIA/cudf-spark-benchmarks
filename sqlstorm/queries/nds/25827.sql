
WITH AddressData AS (
    SELECT 
        ca_city,
        ca_state,
        ca_street_name,
        ca_street_type,
        LENGTH(ca_street_name) AS street_name_length,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state, ca_street_name, ca_street_type
),
AggregateData AS (
    SELECT 
        ca_city,
        ca_state,
        AVG(street_name_length) AS avg_street_name_length,
        SUM(address_count) AS total_addresses
    FROM 
        AddressData
    GROUP BY 
        ca_city, ca_state
)
SELECT 
    ca_city,
    ca_state,
    AVG(avg_street_name_length) OVER (PARTITION BY ca_state) AS avg_length_per_state,
    total_addresses
FROM 
    AggregateData
WHERE 
    total_addresses > 1
ORDER BY 
    ca_state, total_addresses DESC;
