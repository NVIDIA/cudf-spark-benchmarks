
WITH address_parts AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM
        customer_address
),
demographics AS (
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
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    d.full_name,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    s.total_sales,
    s.order_count,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country
FROM
    demographics d
JOIN
    sales_summary s ON d.c_customer_sk = s.ws_bill_customer_sk
JOIN
    address_parts a ON d.c_customer_sk = a.ca_address_sk
WHERE
    a.ca_state = 'CA' AND
    d.cd_purchase_estimate > 1000
ORDER BY
    s.total_sales DESC
LIMIT 50;
