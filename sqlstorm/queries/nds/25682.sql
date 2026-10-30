
WITH RankedCustomers AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressInfo AS (
    SELECT
        ca.ca_address_id,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        SUBSTRING(ca.ca_street_name FROM POSITION(' ' IN ca.ca_street_name) + 1) AS street_name_cleaned
    FROM
        customer_address ca
),
HighValueCustomers AS (
    SELECT
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        ai.street_name_cleaned
    FROM
        RankedCustomers rc
    JOIN
        AddressInfo ai ON rc.c_customer_id = LEFT(ai.ca_address_id, 16)
    WHERE
        rc.rank <= 10
)
SELECT
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
    street_name_cleaned
FROM
    HighValueCustomers
ORDER BY
    cd_gender, cd_marital_status, full_address DESC;
