
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name, c.c_first_name) AS rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressDetails AS (
    SELECT
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM
        customer_address ca
),
CustomerAddress AS (
    SELECT
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        ra.full_address,
        ra.ca_city,
        ra.ca_state,
        ra.ca_zip
    FROM
        RankedCustomers rc
    JOIN
        AddressDetails ra ON rc.c_customer_sk = ra.ca_address_sk
)
SELECT
    ca.c_first_name,
    ca.c_last_name,
    ca.full_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    COUNT(*) OVER (PARTITION BY ca.ca_state) AS total_in_state
FROM
    CustomerAddress ca
WHERE
    ca.c_first_name ILIKE 'A%' OR ca.c_last_name ILIKE 'A%'
ORDER BY
    ca.ca_state, ca.c_last_name, ca.c_first_name;
