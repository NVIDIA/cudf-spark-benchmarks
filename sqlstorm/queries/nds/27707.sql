
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY LENGTH(ca_street_name) DESC) as name_length_rank
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) as total_addresses,
        MAX(name_length_rank) as max_name_length_rank,
        AVG(name_length_rank) as avg_name_length_rank
    FROM 
        RankedAddresses
    GROUP BY 
        ca_state
)
SELECT 
    ca_state,
    total_addresses,
    max_name_length_rank,
    avg_name_length_rank,
    CASE 
        WHEN avg_name_length_rank < 3 THEN 'Short Names'
        WHEN avg_name_length_rank BETWEEN 3 AND 5 THEN 'Medium Names'
        ELSE 'Long Names'
    END as name_length_category
FROM 
    AddressStats
ORDER BY 
    total_addresses DESC, 
    ca_state ASC;
