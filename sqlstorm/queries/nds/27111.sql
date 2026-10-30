
WITH AddressInfo AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    si.total_profit,
    si.total_orders
FROM 
    CustomerInfo ci
JOIN 
    AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
LEFT JOIN 
    SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    (ci.cd_gender = 'F' AND ci.cd_marital_status = 'M') 
    OR (ci.cd_gender = 'M' AND ci.cd_purchase_estimate > 1000)
ORDER BY 
    si.total_profit DESC
LIMIT 50;
