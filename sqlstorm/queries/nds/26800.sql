
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number)) AS full_address,
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
        TRIM(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.full_address,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesMetrics AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_paid) AS avg_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        cm.total_orders,
        cm.total_profit,
        cm.avg_order_value
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesMetrics cm ON ci.c_customer_sk = cm.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_orders,
    total_profit,
    avg_order_value
FROM 
    FinalReport
WHERE 
    (cd_gender = 'M' AND total_orders > 5)
    OR (cd_gender = 'F' AND total_profit > 1000)
ORDER BY 
    cd_gender, total_profit DESC;
