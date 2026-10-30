
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS normalized_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WebSalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
FinalBenchmark AS (
    SELECT 
        AD.full_address,
        CD.customer_name,
        CD.cd_gender,
        CD.cd_marital_status,
        WS.total_quantity,
        WS.total_sales
    FROM AddressDetails AD
    JOIN CustomerDetails CD ON AD.ca_address_sk = CD.c_customer_sk
    JOIN WebSalesDetails WS ON WS.ws_item_sk = CD.c_customer_sk
    WHERE 
        AD.normalized_city LIKE '%new%' 
        AND CD.cd_purchase_estimate > 1000
    ORDER BY WS.total_sales DESC
)
SELECT *
FROM FinalBenchmark
LIMIT 100;
