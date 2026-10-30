
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_street_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.full_street_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressParts ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
CombinedData AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        sd.total_quantity,
        sd.total_profit,
        DENSE_RANK() OVER (PARTITION BY ci.cd_gender ORDER BY sd.total_profit DESC) AS gender_rank
    FROM CustomerInfo ci
    JOIN SalesData sd ON ci.c_customer_sk = sd.ws_item_sk
)
SELECT 
    full_name,
    cd_gender,
    total_quantity,
    total_profit,
    gender_rank
FROM CombinedData
WHERE gender_rank <= 10
ORDER BY cd_gender, total_profit DESC;
