
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
BenchmarkData AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        si.total_sales,
        si.order_count,
        CASE 
            WHEN si.total_sales < 1000 THEN 'Low Value'
            WHEN si.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
            ELSE 'High Value'
        END AS customer_value_segment
    FROM CustomerInfo ci
    LEFT JOIN SalesData si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    total_sales,
    order_count,
    customer_value_segment
FROM BenchmarkData
WHERE cd_gender = 'F'
ORDER BY total_sales DESC, order_count DESC
LIMIT 100;
