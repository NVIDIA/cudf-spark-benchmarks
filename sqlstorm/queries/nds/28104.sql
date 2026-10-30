
WITH AddressParts AS (
    SELECT
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip, ', ', ca_country) AS full_address
    FROM
        customer_address
),
Demographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        UPPER(cd_education_status) AS education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM
        customer_demographics
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        d.cd_gender,
        d.education_status,
        d.cd_purchase_estimate
    FROM
        customer c
    JOIN
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT
    c.c_customer_sk,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.full_address,
    c.cd_gender,
    c.education_status,
    c.cd_purchase_estimate,
    CASE
        WHEN c.cd_purchase_estimate < 100 THEN 'Low'
        WHEN c.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
        ELSE 'High'
    END AS purchase_estimate_category
FROM
    CustomerDetails c
WHERE
    c.cd_gender = 'F'
ORDER BY
    c.cd_purchase_estimate DESC
LIMIT 100;
