
WITH address_details AS (
    SELECT
        a.ca_address_sk,
        CONCAT(a.ca_street_number, ' ', a.ca_street_name, ' ', a.ca_street_type, CASE WHEN a.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', a.ca_suite_number) ELSE '' END) AS full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country
    FROM
        customer_address a
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        da.full_address
    FROM
        customer c
    JOIN
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN
        address_details da ON c.c_current_addr_sk = da.ca_address_sk
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
processed_customers AS (
    SELECT
        ci.customer_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ss.total_sales,
        ss.total_orders,
        CASE
            WHEN ss.total_sales IS NULL THEN 'No Sales'
            WHEN ss.total_sales > 0 AND ss.total_sales <= 100 THEN 'Low Value'
            WHEN ss.total_sales > 100 AND ss.total_sales <= 500 THEN 'Medium Value'
            ELSE 'High Value'
        END AS customer_value_segment
    FROM
        customer_info ci
    LEFT JOIN
        sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT
    customer_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    total_orders,
    customer_value_segment
FROM
    processed_customers
ORDER BY
    total_sales DESC NULLS LAST
LIMIT 100;
