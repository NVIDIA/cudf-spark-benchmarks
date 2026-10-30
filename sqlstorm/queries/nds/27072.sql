
WITH AddressInfo AS (
    SELECT
        ca_address_sk,
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM
        customer_address
),
CustomerInfo AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ci.full_address,
        ci.ca_city,
        ci.ca_state
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressInfo ci ON c.c_current_addr_sk = ci.ca_address_sk
),
SalesInfo AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    si.total_profit,
    si.total_orders,
    CASE
        WHEN si.total_profit > 10000 THEN 'High Value'
        WHEN si.total_profit BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    CONCAT(ci.full_address, ', ', ci.ca_city, ' ', ci.ca_state) AS full_location
FROM
    CustomerInfo ci
LEFT JOIN SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE
    ci.cd_gender = 'F' AND
    ci.cd_marital_status = 'M'
ORDER BY
    total_profit DESC
LIMIT 50;
