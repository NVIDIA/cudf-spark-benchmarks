
WITH AddressConcatenation AS (
    SELECT
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
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
        cd.cd_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
)
SELECT
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    a.full_address,
    a.ca_city,
    a.ca_state,
    s.total_sales,
    s.order_count
FROM
    CustomerDetails c
JOIN
    AddressConcatenation a ON c.c_customer_sk = a.ca_address_sk
LEFT JOIN
    SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE
    c.cd_gender = 'F' AND
    (c.cd_education_status LIKE '%Graduate%' OR c.cd_education_status LIKE '%Master%')
ORDER BY
    s.total_sales DESC, c.full_name ASC
LIMIT 100;
