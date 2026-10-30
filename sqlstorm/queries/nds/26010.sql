
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        COALESCE(cd.cd_education_status, 'Unknown') AS education_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressSummary AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
SalesSummary AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk
)
SELECT 
    cs.full_name,
    cs.gender,
    cs.marital_status,
    cs.education_status,
    cs.purchase_estimate,
    asu.full_address,
    asu.ca_city,
    asu.ca_state,
    asu.ca_zip,
    COALESCE(ss.total_net_profit, 0) AS total_net_profit,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.total_quantity, 0) AS total_quantity
FROM 
    CustomerSummary cs
LEFT JOIN 
    AddressSummary asu ON asu.ca_address_sk = cs.c_customer_sk
LEFT JOIN 
    SalesSummary ss ON ss.ws_ship_customer_sk = cs.c_customer_sk
WHERE 
    cs.purchase_estimate > 5000
ORDER BY 
    total_net_profit DESC
LIMIT 100;
