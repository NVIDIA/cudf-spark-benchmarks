
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        a.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ca.c_customer_sk,
        COUNT(s.ws_order_number) AS total_orders,
        SUM(s.ws_net_profit) AS total_profit
    FROM 
        CustomerInfo ca
    LEFT JOIN 
        web_sales s ON ca.c_customer_sk = s.ws_bill_customer_sk
    GROUP BY 
        ca.c_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.full_address,
    cs.total_orders,
    cs.total_profit
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesSummary cs ON ci.c_customer_sk = cs.c_customer_sk
ORDER BY 
    cs.total_profit DESC, 
    ci.c_last_name ASC
LIMIT 100;
