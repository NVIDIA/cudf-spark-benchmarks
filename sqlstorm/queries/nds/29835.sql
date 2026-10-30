
WITH  address_parts AS (
    SELECT
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_suite_number,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_address_sk ORDER BY ca_street_name) AS rn
    FROM customer_address
),
formatted_addresses AS (
    SELECT
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM address_parts
)
SELECT
    fa.ca_address_sk,
    fa.full_address,
    fa.ca_city,
    fa.ca_state,
    fa.ca_zip,
    fa.ca_country,
    LENGTH(fa.full_address) AS address_length,
    SUBSTRING(fa.full_address, 1, 10) AS address_preview,
    (SELECT COUNT(*) FROM customer WHERE c_current_addr_sk = fa.ca_address_sk) AS customer_count
FROM formatted_addresses fa
WHERE fa.ca_state = 'CA'
ORDER BY address_length DESC
LIMIT 10;
