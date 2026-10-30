
WITH AddressInfo AS (
    SELECT
        ca_address_sk,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_state,
        ca_zip
    FROM
        customer_address
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        dd.d_month_seq AS registration_month,
        dd.d_year AS registration_year
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim dd ON c.c_first_shipto_date_sk = dd.d_date_sk
),
SalesStats AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        ss.total_quantity,
        ss.total_net_profit,
        ss.total_orders
    FROM
        CustomerInfo ci
    LEFT JOIN
        AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
    LEFT JOIN
        SalesStats ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT
    full_name,
    cd_gender,
    cd_marital_status,
    ca_city,
    ca_state,
    ca_zip,
    total_quantity,
    total_net_profit,
    total_orders,
    CASE 
        WHEN total_net_profit IS NULL THEN 'No Sales'
        WHEN total_net_profit <= 0 THEN 'Unprofitable'
        ELSE 'Profitable'
    END AS profit_status
FROM
    CombinedData
WHERE
    ca_state = 'CA'
ORDER BY
    total_net_profit DESC, total_orders DESC;
