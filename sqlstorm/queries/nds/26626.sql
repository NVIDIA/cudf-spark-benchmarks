
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
CustomerBenchmark AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        COALESCE(sd.total_profit, 0) AS total_profit,
        COALESCE(sd.order_count, 0) AS order_count
    FROM CustomerInfo ci
    JOIN AddressDetails ad ON ci.c_customer_sk = ad.ca_address_sk
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    full_address,
    ca_city,
    ca_state,
    total_profit,
    order_count,
    CASE 
        WHEN total_profit > 1000 THEN 'High Value'
        WHEN total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM CustomerBenchmark
ORDER BY total_profit DESC, order_count DESC
LIMIT 50;
