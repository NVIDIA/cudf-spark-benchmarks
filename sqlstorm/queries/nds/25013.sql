
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
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
),
CombinedInfo AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        ai.ca_country,
        si.total_profit,
        si.total_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_ship_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_profit > 1000 THEN 'High Profit'
        WHEN total_profit > 500 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    CombinedInfo
WHERE 
    cd_marital_status = 'M'
ORDER BY 
    total_profit DESC, full_name ASC
LIMIT 100;
