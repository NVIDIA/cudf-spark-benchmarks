
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_first_name, c.c_last_name) AS rn
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        ca.ca_city IS NOT NULL
),
StringProcessed AS (
    SELECT
        csk.c_customer_sk,
        CONCAT(UPPER(SUBSTRING(csk.c_first_name, 1, 1)), LOWER(SUBSTRING(csk.c_first_name, 2))) AS formatted_first_name,
        CONCAT(UPPER(SUBSTRING(csk.c_last_name, 1, 1)), LOWER(SUBSTRING(csk.c_last_name, 2))) AS formatted_last_name,
        csk.cd_gender,
        csk.cd_marital_status,
        csk.ca_city
    FROM
        RankedCustomers csk
    WHERE
        csk.rn <= 10
)
SELECT
    sp.formatted_first_name,
    sp.formatted_last_name,
    sp.cd_gender,
    sp.cd_marital_status,
    sp.ca_city,
    COUNT(*) AS customer_count
FROM
    StringProcessed sp
GROUP BY
    sp.formatted_first_name,
    sp.formatted_last_name,
    sp.cd_gender,
    sp.cd_marital_status,
    sp.ca_city
ORDER BY
    sp.ca_city, sp.formatted_last_name, sp.formatted_first_name;
