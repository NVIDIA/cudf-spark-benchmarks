
WITH CustomerInfo AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressInfo AS (
    SELECT 
        ca_address_sk, 
        TRIM(ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CompleteInfo AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        sd.total_spent,
        sd.order_count
    FROM CustomerInfo ci
    JOIN AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
    JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    cd_purchase_estimate, 
    cd_credit_rating,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    total_spent,
    order_count,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM CompleteInfo
ORDER BY total_spent DESC
LIMIT 50;
