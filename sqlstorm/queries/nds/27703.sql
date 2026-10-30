
WITH  address_parts AS (
    SELECT
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS row_num
    FROM
        customer_address
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        a.full_address,
        a.row_num
    FROM
        customer c
    JOIN
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN
        address_parts a ON c.c_current_addr_sk = a.ca_address_sk
),
aggregated_data AS (
    SELECT
        ci.row_num,
        ci.full_address,
        COUNT(*) AS customer_count,
        STRING_AGG(CONCAT(ci.c_first_name, ' ', ci.c_last_name), ', ') AS customer_names
    FROM
        customer_info ci
    GROUP BY
        ci.row_num, ci.full_address
)
SELECT
    row_num,
    full_address,
    customer_count,
    customer_names
FROM
    aggregated_data
WHERE
    customer_count > 1
ORDER BY
    row_num, full_address;
