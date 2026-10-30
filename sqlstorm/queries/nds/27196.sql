WITH AddressInfo AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(' Apt ' || ca_suite_number, ''), ', ', ca_city, ', ', ca_state) AS full_address
    FROM
        customer_address
),
CustomerInfo AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM
        customer AS c
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
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
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ai.full_address,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.order_count, 0) AS number_of_orders,
    CASE
        WHEN COALESCE(si.total_sales, 0) > 1000 THEN 'High Value Customer'
        WHEN COALESCE(si.total_sales, 0) > 100 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM
    CustomerInfo AS ci
LEFT JOIN
    AddressInfo AS ai ON ai.ca_address_sk = ci.c_customer_sk  
LEFT JOIN
    SalesInfo AS si ON si.ws_bill_customer_sk = ci.c_customer_sk
ORDER BY
    customer_segment DESC, ci.full_name
LIMIT 100;