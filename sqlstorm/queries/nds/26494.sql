
WITH AddressConcat AS (
    SELECT
        ca.ca_address_sk,
        CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, 
                  COALESCE(ca.ca_suite_number, ''), ca.ca_city, ca.ca_state, ca.ca_zip, ca.ca_country) AS full_address
    FROM
        customer_address ca
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT_WS(' ', c.c_first_name, c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.full_address
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressConcat ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateInfo AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        CONCAT(d.d_month_seq, '-', d.d_year) AS month_year
    FROM
        date_dim d
    WHERE
        d.d_year >= 2020
),
SalesInfo AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM DateInfo d)
    GROUP BY
        ws.ws_bill_customer_sk
)
SELECT
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.full_address,
    COALESCE(si.total_profit, 0) AS total_profit,
    COALESCE(si.order_count, 0) AS order_count
FROM
    CustomerInfo ci
LEFT JOIN SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
ORDER BY
    total_profit DESC,
    order_count DESC
LIMIT 100;
