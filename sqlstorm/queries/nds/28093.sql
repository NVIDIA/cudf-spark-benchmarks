
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, '-', cd_marital_status, '-', cd_education_status) AS demo_profile,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM customer_demographics
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
FinalBenchmark AS (
    SELECT 
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        d.demo_profile,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.order_count, 0) AS order_count
    FROM AddressParts a
    JOIN customer c ON a.ca_address_sk = c.c_current_addr_sk
    JOIN Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    demo_profile,
    cd_purchase_estimate,
    cd_credit_rating,
    cd_dep_count,
    total_sales,
    order_count,
    (CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END) AS customer_value_segment
FROM FinalBenchmark
ORDER BY total_sales DESC;
