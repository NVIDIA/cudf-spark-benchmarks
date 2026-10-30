
WITH AddressInfo AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        UPPER(ca_city) AS city_upper,
        ca_state,
        ca_zip
    FROM
        customer_address
),
DemographicInfo AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        CONCAT(cd_dep_count, ' dependents') AS dependent_info
    FROM
        customer_demographics
),
DateInfo AS (
    SELECT
        d_date_sk,
        d_date,
        d_month_seq,
        d_year,
        d_day_name,
        CASE
            WHEN d_day_name IN ('Saturday', 'Sunday') THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type
    FROM
        date_dim
),
SalesInfo AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_item_sk
)
SELECT
    ai.full_address,
    di.cd_gender,
    di.cd_marital_status,
    di.cd_education_status,
    di.dependent_info,
    di.cd_purchase_estimate,
    di.cd_credit_rating,
    di.cd_demo_sk,
    CONCAT(di.cd_demo_sk, '-', ai.ca_zip) AS unique_identifier,
    CONCAT(di.dependent_info, ' in ', ai.city_upper) AS demographic_address,
    CONCAT(di.cd_gender, ' and ', di.cd_marital_status) AS gender_marital,
    si.total_sales,
    si.order_count,
    (di.cd_demo_sk IN (SELECT DISTINCT cd_demo_sk FROM customer)) AS has_customers,
    (di.cd_purchase_estimate > 10000) AS high_purchase_estimate,
    CONCAT(di.cd_gender, ' - ', di.cd_education_status) AS gender_education
FROM
    AddressInfo ai
JOIN
    DemographicInfo di ON ai.ca_address_sk = di.cd_demo_sk
JOIN
    DateInfo de ON de.d_date_sk = ai.ca_address_sk
LEFT JOIN
    SalesInfo si ON si.ws_item_sk = ai.ca_address_sk
WHERE
    ai.full_address LIKE '%Main St%'
    AND di.cd_marital_status = 'M'
    AND de.d_year = 2023
ORDER BY
    si.total_sales DESC
LIMIT 50;
