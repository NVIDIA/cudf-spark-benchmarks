
WITH AddressParts AS (
    SELECT
        ca_address_sk,
        CONCAT(
            COALESCE(ca_street_number, ''), ' ',
            COALESCE(ca_street_name, ''), ' ',
            COALESCE(ca_street_type, ''), ' ',
            COALESCE(ca_suite_number, '')
        ) AS full_address
    FROM
        customer_address
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        a.full_address
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    sd.total_sales,
    sd.order_count,
    cd.full_address
FROM
    CustomerDetails cd
LEFT JOIN
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE
    cd.cd_purchase_estimate > 1000
ORDER BY
    total_sales DESC, full_name ASC
LIMIT 100;
