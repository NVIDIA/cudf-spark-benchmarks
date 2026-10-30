
WITH StringBenchmarks AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip)) AS address_length,
        LEFT(ca_city, 3) AS city_prefix,
        UPPER(ca_country) AS country_upper,
        REGEXP_REPLACE(ca_street_name, '[^a-zA-Z ]', '') AS clean_street_name
    FROM 
        customer_address
),
UniqueCount AS (
    SELECT 
        COUNT(DISTINCT full_address) AS unique_addresses,
        AVG(address_length) AS avg_address_length,
        COUNT(DISTINCT city_prefix) AS unique_city_prefixes,
        COUNT(DISTINCT country_upper) AS unique_countries
    FROM 
        StringBenchmarks
)
SELECT 
    u.unique_addresses,
    u.avg_address_length,
    u.unique_city_prefixes,
    u.unique_countries,
    (SELECT COUNT(*) FROM customer) AS total_customers,
    (SELECT COUNT(*) FROM item WHERE LENGTH(i_item_desc) > 50) AS long_item_desc_count
FROM 
    UniqueCount u;
