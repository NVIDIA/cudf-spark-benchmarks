
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        REPLACE(REPLACE(REPLACE(ca_city, ' ', ''), '-', ''), ',', '') AS clean_city,
        UPPER(ca_state) AS upper_state,
        SUBSTR(ca_zip, 1, 5) AS zip_code
    FROM 
        customer_address
),
address_stats AS (
    SELECT 
        upper_state,
        COUNT(DISTINCT ca_address_sk) AS address_count,
        AVG(LENGTH(full_address)) AS avg_full_address_length,
        MAX(LENGTH(clean_city)) AS max_clean_city_length,
        MIN(LENGTH(clean_city)) AS min_clean_city_length,
        COUNT(DISTINCT zip_code) AS unique_zip_count
    FROM 
        processed_addresses
    GROUP BY 
        upper_state
)
SELECT 
    upper_state,
    address_count,
    avg_full_address_length,
    max_clean_city_length,
    min_clean_city_length,
    unique_zip_count
FROM 
    address_stats
ORDER BY 
    address_count DESC, 
    unique_zip_count DESC;
