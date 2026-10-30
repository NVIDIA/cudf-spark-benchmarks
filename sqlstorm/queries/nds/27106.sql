
WITH CustomerLocation AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM customer_demographics
),
ActiveCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cl.full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN CustomerLocation cl ON c.c_current_addr_sk = cl.ca_address_sk
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_customer_id IS NOT NULL
),
SalesData AS (
    SELECT 
        ws_ship_date_sk,
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_ship_date_sk, ws_bill_customer_sk, ws_item_sk
)
SELECT 
    ac.c_customer_sk,
    ac.c_first_name,
    ac.c_last_name,
    ac.full_address,
    ac.cd_gender,
    ac.cd_marital_status,
    ac.cd_education_status,
    sd.ws_ship_date_sk,
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_net_profit
FROM ActiveCustomers ac
JOIN SalesData sd ON ac.c_customer_sk = sd.ws_bill_customer_sk
WHERE ac.cd_gender = 'F' 
AND ac.cd_marital_status = 'M'
ORDER BY sd.total_net_profit DESC, sd.total_quantity DESC
LIMIT 100;
