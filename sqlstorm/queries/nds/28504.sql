
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
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_sales_price) AS total_revenue,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    ai.ca_country,
    si.total_sales,
    si.total_revenue,
    si.total_profit
FROM 
    CustomerInfo ci
JOIN 
    AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
JOIN 
    SalesInfo si ON ci.c_customer_sk = si.ws_item_sk
WHERE 
    ci.cd_gender = 'F'
    AND ci.cd_marital_status = 'M'
    AND si.total_revenue > 1000
ORDER BY 
    si.total_profit DESC
LIMIT 100;
