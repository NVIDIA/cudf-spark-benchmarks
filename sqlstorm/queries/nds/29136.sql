
WITH processed_addresses AS (
    SELECT
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        CONCAT(UPPER(ca_city), ', ', UPPER(ca_state), ' ', ca_zip) AS city_state_zip
    FROM
        customer_address
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.full_address,
        ca.city_state_zip
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        processed_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.full_address,
    cs.city_state_zip,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.order_count, 0) AS order_count
FROM
    customer_summary cs
LEFT JOIN
    sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
WHERE
    cs.cd_gender = 'F'
    AND cs.cd_marital_status = 'M'
ORDER BY
    total_sales DESC
LIMIT 100;
