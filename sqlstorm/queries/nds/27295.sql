
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END,
               ', ', TRIM(ca_city), ', ', TRIM(ca_state), ' ', TRIM(ca_zip), ' ', TRIM(ca_country)) AS full_address,
        LENGTH(TRIM(ca_street_number) || ' ' || TRIM(ca_street_name) || ' ' || TRIM(ca_street_type) || 
               COALESCE(CONCAT(' Suite ', TRIM(ca_suite_number)), '') || ', ' || TRIM(ca_city) || ', ' || 
               TRIM(ca_state) || ' ' || TRIM(ca_zip) || ' ' || TRIM(ca_country)) AS address_length
    FROM
        customer_address
    WHERE 
        ca_state IN ('CA', 'TX', 'NY') AND TRIM(ca_city) <> ''
)
SELECT 
    SUBSTR(full_address, 1, 50) AS address_excerpt,
    address_length,
    COUNT(*) OVER (PARTITION BY address_length) AS address_count
FROM 
    processed_addresses
ORDER BY 
    address_length DESC, address_excerpt
LIMIT 100;
