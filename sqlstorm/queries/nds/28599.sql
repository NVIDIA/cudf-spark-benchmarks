
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS birth_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_birth_year = d.d_year AND c.c_birth_month = d.d_moy AND c.c_birth_day = d.d_dom
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        ci.full_name,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        si.total_orders,
        si.total_profit,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    total_orders,
    total_profit,
    cd_gender,
    cd_marital_status,
    cd_education_status
FROM 
    CombinedInfo
WHERE 
    total_profit > 1000 AND 
    cd_marital_status = 'M'
ORDER BY 
    total_profit DESC, 
    full_name;
