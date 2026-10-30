
WITH AddressInfo AS (
    SELECT
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_street_address,
        TRIM(CONCAT(ca_city, ', ', ca_state, ' ', ca_zip)) AS city_state_zip,
        ca_country
    FROM
        customer_address
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        TRIM(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        TRIM(CONCAT(cd.cd_dep_count, ' dependents (', cd.cd_dep_employed_count, ' employed, ', cd.cd_dep_college_count, ' in college)')) AS dependents_info
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
CustomerAnalytics AS (
    SELECT
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ai.full_street_address,
        ai.city_state_zip,
        ai.ca_country,
        COALESCE(si.total_sales, 0) AS total_sales,
        COALESCE(si.total_orders, 0) AS total_orders
    FROM
        CustomerInfo ci
    JOIN
        AddressInfo ai ON ai.ca_address_sk = ci.c_customer_sk
    LEFT JOIN
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_street_address,
    city_state_zip,
    ca_country,
    total_sales,
    total_orders,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM 
    CustomerAnalytics
ORDER BY 
    total_sales DESC;
