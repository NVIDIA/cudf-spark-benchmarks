
WITH AddressInfo AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        UPPER(ca_country) AS country
    FROM
        customer_address
),
Demographics AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    d.customer_name,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.cd_purchase_estimate,
    d.cd_credit_rating,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.country,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.order_count, 0) AS order_count
FROM
    Demographics d
JOIN
    AddressInfo a ON d.c_customer_sk = a.ca_address_sk
LEFT JOIN
    SalesData s ON d.c_customer_sk = s.ws_bill_customer_sk
WHERE
    d.cd_gender = 'F'
    AND d.cd_purchase_estimate > 1000
ORDER BY
    total_sales DESC
LIMIT 10;
