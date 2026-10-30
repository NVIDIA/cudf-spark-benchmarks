
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
        CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END)) AS full_address,
        ca_city, 
        ca_state
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count AS dependent_count
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.full_name, 
    c.cd_gender, 
    c.cd_marital_status, 
    s.total_orders, 
    s.total_sales, 
    a.full_address, 
    a.ca_city, 
    a.ca_state
FROM CustomerDetails c
JOIN AddressDetails a ON c.c_customer_sk = a.ca_address_sk
JOIN SalesSummary s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE c.cd_purchase_estimate > 50000
    AND a.ca_state = 'CA'
ORDER BY s.total_sales DESC
LIMIT 50;
