
WITH AddressConcat AS (
    SELECT 
        ca_address_sk,
        CONCAT(
            COALESCE(ca_street_number, ''), ' ', 
            COALESCE(ca_street_name, ''), ' ', 
            COALESCE(ca_street_type, ''), ', ',
            COALESCE(ca_city, ''), ', ', 
            COALESCE(ca_state, ''), ' ', 
            COALESCE(ca_zip, ''), ', ', 
            COALESCE(ca_country, '')
        ) AS full_address
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        addr.full_address
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN AddressConcat addr ON c.c_current_addr_sk = addr.ca_address_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    LENGTH(ci.full_address) AS address_length,
    UPPER(ci.full_address) AS upper_case_address,
    REPLACE(ci.full_address, ',', '') AS address_no_commas
FROM CustomerInfo ci
WHERE ci.cd_gender = 'F'
ORDER BY address_length DESC
LIMIT 100;
