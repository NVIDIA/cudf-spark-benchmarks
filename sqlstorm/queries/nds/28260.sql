
WITH AddressInfo AS (
    SELECT
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               COALESCE(CONCAT(' ', TRIM(ca_suite_number)), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerInfo AS (
    SELECT
        c_customer_sk,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesInfo AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(*) AS total_purchases,
        SUM(ws_net_paid) AS total_spent
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
Benchmark AS (
    SELECT
        ci.full_name,
        ci.cd_gender,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        si.total_purchases,
        si.total_spent,
        CASE 
            WHEN si.total_spent > 1000 THEN 'High Value'
            WHEN si.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM CustomerInfo ci
    JOIN AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk  
    LEFT JOIN SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT
    customer_value_category,
    COUNT(*) AS num_customers,
    AVG(total_spent) AS average_spent
FROM Benchmark
GROUP BY customer_value_category
ORDER BY num_customers DESC;
