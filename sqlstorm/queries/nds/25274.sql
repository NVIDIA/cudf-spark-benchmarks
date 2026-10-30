
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),

CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),

FinalBenchmark AS (
    SELECT 
        cd.full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        sd.total_quantity,
        sd.total_profit
    FROM CustomerDetails cd
    JOIN AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)

SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(total_profit, 0) AS total_profit,
    CASE 
        WHEN total_profit > 1000 THEN 'High Value Customer'
        WHEN total_profit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM FinalBenchmark
ORDER BY total_profit DESC;
