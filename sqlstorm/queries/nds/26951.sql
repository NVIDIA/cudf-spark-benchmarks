
WITH CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FormattedDetails AS (
    SELECT
        c.c_customer_sk,
        c.full_name,
        c.ca_city,
        c.ca_state,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        c.cd_purchase_estimate,
        UPPER(SUBSTRING(c.full_name, 1, POSITION(' ' IN c.full_name) - 1)) AS upper_first_name,
        LENGTH(c.full_name) AS name_length,
        REPLACE(c.full_name, ' ', '-') AS name_with_hyphen
    FROM
        CustomerDetails c
)
SELECT
    fd.full_name,
    fd.ca_city,
    fd.ca_state,
    fd.cd_gender,
    fd.cd_marital_status,
    fd.cd_education_status,
    fd.cd_purchase_estimate,
    fd.upper_first_name,
    fd.name_length,
    fd.name_with_hyphen
FROM
    FormattedDetails fd
WHERE
    fd.cd_gender = 'F'
    AND fd.cd_marital_status = 'M'
    AND fd.cd_purchase_estimate > 50000
ORDER BY
    fd.name_length DESC;
