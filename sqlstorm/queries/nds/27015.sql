
WITH AddressComponents AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address, 
        ca_city, 
        ca_state, 
        ca_zip, 
        ca_country
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name, 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status,
        cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
BenchmarkResult AS (
    SELECT 
        ci.full_name, 
        ci.cd_gender, 
        ci.cd_marital_status, 
        ci.cd_education_status, 
        ac.full_address,
        ac.ca_city,
        ac.ca_state,
        ac.ca_zip,
        ac.ca_country,
        sd.total_sales,
        sd.total_orders
    FROM CustomerInfo ci
    LEFT JOIN AddressComponents ac ON ci.c_customer_sk = ac.ca_address_sk
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales IS NULL THEN 0 
        ELSE total_sales 
    END AS adjusted_sales,
    CASE 
        WHEN total_orders IS NULL THEN 0 
        ELSE total_orders 
    END AS adjusted_orders
FROM BenchmarkResult
WHERE cd_gender = 'F' 
AND cd_marital_status = 'M'
ORDER BY total_sales DESC
LIMIT 100;
