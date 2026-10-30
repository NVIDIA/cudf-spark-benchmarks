
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        REPLACE(CONCAT(c.c_first_name, ' ', c.c_last_name), ' ', '-') AS full_name_slug,
        CONCAT(c.c_first_name, '-', SUBSTR(c.c_last_name, 1, 1)) AS short_name_slug
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS orders_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)

SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.orders_count, 0) AS orders_count,
    ci.full_name_slug,
    ci.short_name_slug
FROM CustomerInfo ci
LEFT JOIN SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE ci.cd_purchase_estimate > 5000
ORDER BY total_sales DESC, ci.c_last_name ASC
LIMIT 100;
