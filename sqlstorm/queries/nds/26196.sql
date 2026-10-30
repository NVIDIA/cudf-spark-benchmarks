
WITH AddressConcat AS (
    SELECT
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                    THEN CONCAT(' Suite ', TRIM(ca_suite_number) ) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM
        customer_address
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender,
        cd.cd_marital_status AS marital_status,
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressConcat ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT
        ci.full_name,
        ci.gender,
        ci.marital_status,
        ci.full_address,
        ci.ca_city,
        ci.ca_state,
        ci.ca_zip,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(sd.total_spent, 0) AS total_spent
    FROM
        CustomerInfo ci
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT
    *,
    CASE 
        WHEN total_spent = 0 THEN 'No Purchases'
        WHEN total_spent < 100 THEN 'Low Value Customer'
        WHEN total_spent BETWEEN 100 AND 500 THEN 'Mid Value Customer'
        ELSE 'High Value Customer'
    END AS customer_value_segment
FROM
    FinalReport
ORDER BY
    total_spent DESC, full_name;
