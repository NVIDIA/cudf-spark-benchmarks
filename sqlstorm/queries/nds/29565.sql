
WITH address_data AS (
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
customer_data AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM
        customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
sales_data AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
aggregated_data AS (
    SELECT
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_purchase_estimate,
        c.cd_credit_rating,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_orders, 0) AS total_orders
    FROM
        customer_data c
    JOIN address_data a ON c.c_customer_sk = a.ca_address_sk
    LEFT JOIN sales_data s ON c.c_customer_sk = s.customer_sk
)
SELECT
    CONCAT_WS(', ', full_name, full_address, ca_city, ca_state, ca_zip, ca_country) AS customer_info,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    cd_credit_rating,
    total_sales,
    total_orders
FROM
    aggregated_data
WHERE
    (cd_gender = 'F' AND total_sales > 1000) OR
    (cd_gender = 'M' AND total_orders > 5)
ORDER BY
    total_sales DESC,
    full_name ASC
LIMIT 100;
