
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        REPLACE(ca_city, ' ', '-') AS city_slug,
        ca_state,
        UPPER(ca_country) AS country_upper
    FROM 
        customer_address
),
AddressAnalytics AS (
    SELECT 
        full_address,
        city_slug,
        ca_state,
        country_upper,
        CHAR_LENGTH(full_address) AS address_length,
        (LENGTH(full_address) - LENGTH(REPLACE(full_address, ' ', ''))) + 1 AS word_count
    FROM 
        ProcessedAddresses
)
SELECT 
    city_slug, 
    ca_state, 
    country_upper,
    AVG(address_length) AS avg_address_length,
    AVG(word_count) AS avg_word_count,
    COUNT(*) AS total_addresses
FROM 
    AddressAnalytics
GROUP BY 
    city_slug, ca_state, country_upper
ORDER BY 
    avg_address_length DESC,
    total_addresses DESC
LIMIT 10;
