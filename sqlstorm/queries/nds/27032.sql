
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip,
        TRIM(ca_country) AS country
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ai.full_address,
        ai.city,
        ai.state,
        ai.zip,
        ai.country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressParts ai ON c.c_current_addr_sk = ai.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(ws_order_number) AS order_count,
        MIN(ws_sold_date_sk) AS first_order,
        MAX(ws_sold_date_sk) AS last_order
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ss.total_spent,
    ss.order_count,
    ss.first_order,
    ss.last_order,
    ci.full_address,
    ci.city,
    ci.state,
    ci.zip,
    ci.country
FROM CustomerInfo ci
JOIN SalesSummary ss ON ci.c_customer_sk = ss.customer_sk
WHERE ci.cd_gender = 'F' 
AND ss.total_spent > 1000
AND ci.state IN ('CA', 'NY')
ORDER BY ss.last_order DESC;
