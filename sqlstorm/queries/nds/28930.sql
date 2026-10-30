
WITH processed_addresses AS (
    SELECT
        ca_address_sk,
        ca_street_number || ' ' || ca_street_name || ' ' || ca_suite_number AS full_address,
        UPPER(ca_city) AS city_upper,
        CONCAT(ca_state, ' - ', ca_country) AS state_country,
        LENGTH(ca_zip) AS zip_length
    FROM
        customer_address
),
demographic_info AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        REPLACE(cd_education_status, ' ', '-') AS edu_status_formatted,
        cd_purchase_estimate,
        CONCAT('Credit: ', cd_credit_rating) AS credit_info
    FROM
        customer_demographics
),
sales_summary AS (
    SELECT
        ws_bill_cdemo_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_cdemo_sk
)
SELECT
    a.ca_address_sk,
    a.full_address,
    a.city_upper,
    a.state_country,
    a.zip_length,
    d.cd_gender,
    d.edu_status_formatted,
    d.cd_purchase_estimate,
    d.credit_info,
    COALESCE(s.total_profit, 0) AS total_sales_profit,
    COALESCE(s.order_count, 0) AS total_orders
FROM
    processed_addresses a
LEFT JOIN
    demographic_info d ON a.ca_address_sk = d.cd_demo_sk
LEFT JOIN
    sales_summary s ON d.cd_demo_sk = s.ws_bill_cdemo_sk
WHERE
    a.zip_length BETWEEN 5 AND 10
ORDER BY
    a.city_upper, d.cd_purchase_estimate DESC;
