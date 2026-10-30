
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        UPPER(ca_city) AS uppercase_city,
        LOWER(ca_county) AS lowercase_county,
        TRIM(COALESCE(ca_suite_number, '')) AS trimmed_suite,
        ca_state,
        ca_country
    FROM 
        customer_address
),
FilteredAddresses AS (
    SELECT 
        *,
        LENGTH(full_address) AS address_length,
        CASE 
            WHEN LENGTH(full_address) > 50 THEN 'Long Address' 
            ELSE 'Short Address' 
        END AS address_size
    FROM 
        ProcessedAddresses
    WHERE 
        UPPER(ca_state) IN ('CA', 'NY', 'TX') 
        AND ca_country = 'USA'
)
SELECT 
    uppercase_city,
    COUNT(*) AS address_count,
    address_size,
    MAX(address_length) AS max_address_length
FROM 
    FilteredAddresses
GROUP BY 
    uppercase_city, address_size
ORDER BY 
    address_count DESC, uppercase_city ASC;
