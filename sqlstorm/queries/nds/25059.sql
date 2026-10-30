
WITH AddressInfo AS (
    SELECT
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_state, ' ', ca_zip) AS full_address
    FROM
        customer_address
),
CustomerInfo AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_country,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        (SELECT COUNT(*) FROM customer_demographics WHERE cd_demo_sk = c_current_cdemo_sk) AS demographic_count
    FROM
        customer
),
SalesInfo AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_order_value
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    ci.full_name,
    ci.demographic_count,
    ai.full_address,
    si.total_net_profit,
    si.total_orders,
    si.avg_order_value
FROM
    CustomerInfo ci
JOIN
    AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
JOIN
    SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE
    ci.demographic_count > 0
ORDER BY
    si.total_net_profit DESC
LIMIT 100;
