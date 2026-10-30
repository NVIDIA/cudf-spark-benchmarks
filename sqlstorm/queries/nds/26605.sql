
WITH address_info AS (
    SELECT
        ca_address_sk,
        TRIM(ca_street_number) || ' ' || TRIM(ca_street_name) || ' ' || TRIM(ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
customer_info AS (
    SELECT
        c_customer_sk,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        c_current_addr_sk
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
sales_info AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
demographics_sales AS (
    SELECT
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        si.total_sales,
        si.total_orders,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        ai.ca_country
    FROM customer_info ci
    LEFT JOIN sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
    LEFT JOIN address_info ai ON ci.c_current_addr_sk = ai.ca_address_sk
)
SELECT
    ds.full_name,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_purchase_estimate,
    ds.cd_credit_rating,
    ds.total_sales,
    ds.total_orders,
    ds.full_address,
    ds.ca_city,
    ds.ca_state,
    ds.ca_zip,
    ds.ca_country,
    CASE 
        WHEN ds.total_sales > 1000 THEN 'High Value'
        WHEN ds.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM demographics_sales ds
WHERE ds.cd_purchase_estimate IS NOT NULL
ORDER BY ds.total_sales DESC
LIMIT 100;
