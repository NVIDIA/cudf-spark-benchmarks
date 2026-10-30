
WITH AddressInfo AS (
    SELECT
        ca.ca_address_sk,
        CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM customer_address ca
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ext_sales_price,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_bill_customer_sk
    FROM web_sales ws
    UNION ALL
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
)
SELECT
    ci.full_name,
    ci.cd_gender,
    ai.full_address,
    si.ws_order_number,
    SUM(si.ws_quantity) AS total_quantity,
    SUM(si.ws_net_paid) AS total_spent,
    SUM(si.ws_ext_sales_price) AS total_sales
FROM CustomerInfo ci
JOIN AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
JOIN SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
GROUP BY
    ci.full_name,
    ci.cd_gender,
    ai.full_address,
    si.ws_order_number
ORDER BY
    total_spent DESC,
    total_quantity DESC
LIMIT 100;
