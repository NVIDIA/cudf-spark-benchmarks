
WITH CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemInfo AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_current_price
    FROM
        item i
),
SalesInfo AS (
    SELECT
        ws.ws_ship_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        web_sales ws
    GROUP BY
        ws.ws_ship_customer_sk
),
BenchmarkData AS (
    SELECT
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ii.i_item_desc,
        ii.i_brand,
        ii.i_current_price,
        si.total_quantity,
        si.total_profit
    FROM
        CustomerInfo ci
    JOIN
        SalesInfo si ON ci.c_customer_sk = si.ws_ship_customer_sk
    JOIN
        ItemInfo ii ON si.ws_ship_customer_sk = ii.i_item_sk
)
SELECT
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    i_item_desc,
    i_brand,
    i_current_price,
    total_quantity,
    total_profit,
    CONCAT(cd_gender, ' - ', cd_marital_status) AS gender_marital_status
FROM
    BenchmarkData
WHERE
    cd_purchase_estimate > 1000
ORDER BY
    total_profit DESC,
    total_quantity DESC
LIMIT 100;
