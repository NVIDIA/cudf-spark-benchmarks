
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_ship_date_sk,
        ws.ws_bill_customer_sk
    FROM web_sales ws 
    WHERE ws.ws_ship_date_sk IS NOT NULL
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ai.full_address,
    SUM(sd.ws_quantity) AS total_quantity,
    SUM(sd.ws_sales_price) AS total_sales_price,
    SUM(sd.ws_net_profit) AS total_net_profit
FROM CustomerInfo ci
JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
JOIN AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
GROUP BY 
    ci.full_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ai.full_address
ORDER BY total_net_profit DESC
LIMIT 10;
