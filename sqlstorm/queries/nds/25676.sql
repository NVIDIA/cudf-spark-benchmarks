
WITH AddressParts AS (
    SELECT
        ca_address_sk,
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type || 
        CASE 
            WHEN ca_suite_number IS NOT NULL THEN ' Suite ' || ca_suite_number 
            ELSE '' 
        END AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressParts ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.full_address,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    ci.ca_country,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count
FROM CustomerInfo ci
LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE ci.ca_state = 'CA'
ORDER BY total_sales DESC, ci.c_last_name;
