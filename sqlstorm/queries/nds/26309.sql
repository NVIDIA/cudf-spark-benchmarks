
WITH address_parts AS (
    SELECT
        ca_address_sk,
        TRIM(ca_street_number) AS street_number,
        INITCAP(LOWER(ca_street_name)) AS street_name,
        INITCAP(LOWER(ca_street_type)) AS street_type,
        CA_CITY AS city,
        CA_STATE AS state,
        CA_ZIP AS zip,
        CA_COUNTRY AS country
    FROM
        customer_address
),
formatted_addresses AS (
    SELECT
        ca_address_sk,
        CONCAT(street_number, ' ', street_name, ' ', street_type, ', ', city, ', ', state, ' ', zip, ', ', country) AS full_address
    FROM
        address_parts
),
unique_addresses AS (
    SELECT
        full_address,
        COUNT(*) AS address_count
    FROM
        formatted_addresses
    GROUP BY
        full_address
    HAVING
        COUNT(*) > 1
)
SELECT 
    ua.full_address,
    ua.address_count,
    'Duplicate Address' AS issue
FROM 
    unique_addresses ua
ORDER BY 
    ua.address_count DESC;
