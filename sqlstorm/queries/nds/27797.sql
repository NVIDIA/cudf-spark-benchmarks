
WITH CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
FinalReport AS (
    SELECT
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        COALESCE(sd.total_profit, 0) AS total_profit,
        COALESCE(sd.order_count, 0) AS order_count
    FROM CustomerInfo ci
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country,
    total_profit,
    order_count,
    CASE
        WHEN total_profit > 1000 THEN 'High Value Customer'
        WHEN total_profit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM FinalReport
ORDER BY total_profit DESC, order_count DESC;
