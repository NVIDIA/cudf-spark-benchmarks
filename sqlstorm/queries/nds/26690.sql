
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        SUBSTRING(ca_street_name FROM 1 FOR POSITION(' ' IN ca_street_name) - 1) AS first_word,
        LENGTH(ca_street_name) AS street_length,
        COUNT(*) OVER (PARTITION BY ca_state) AS state_count
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL 
        AND ca_state IS NOT NULL
),
FilteredAddresses AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state, 
        first_word,
        street_length,
        state_count,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY street_length DESC) AS rn
    FROM 
        RankedAddresses
    WHERE 
        first_word IS NOT NULL
    AND LENGTH(first_word) > 3
)
SELECT 
    ca_state, 
    COUNT(*) AS address_count, 
    AVG(street_length) AS avg_street_length,
    MAX(first_word) AS longest_first_word
FROM 
    FilteredAddresses
GROUP BY 
    ca_state
HAVING 
    COUNT(*) > 5
ORDER BY 
    address_count DESC;
