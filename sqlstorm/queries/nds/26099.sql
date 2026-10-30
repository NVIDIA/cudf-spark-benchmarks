
WITH AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE 
                   WHEN ca.ca_suite_number IS NOT NULL AND ca.ca_suite_number <> '' 
                   THEN CONCAT(' Suite ', ca.ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        r.r_reason_desc
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_ship_mode_sk,
        sm.sm_type AS shipping_type
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    UNION ALL
    SELECT 
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cs.cs_ship_mode_sk,
        sm.sm_type AS shipping_type
    FROM 
        catalog_sales cs
    JOIN 
        ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    UNION ALL
    SELECT 
        ss.ss_ticket_number AS ws_order_number,
        ss.ss_sales_price,
        ss.ss_net_profit,
        NULL AS cs_ship_mode_sk,
        NULL AS shipping_type
    FROM 
        store_sales ss
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    si.ws_order_number,
    si.ws_sales_price,
    si.ws_net_profit,
    si.shipping_type
FROM 
    CustomerInfo ci
JOIN 
    AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
LEFT JOIN 
    SalesInfo si ON ci.c_customer_sk = si.ws_order_number
WHERE 
    ci.cd_gender = 'F' AND ci.cd_marital_status = 'M'
ORDER BY 
    si.ws_sales_price DESC;
