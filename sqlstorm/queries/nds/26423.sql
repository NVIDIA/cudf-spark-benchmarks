
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CONCAT(cd_gender, '-', cd_marital_status, '-', cd_education_status) AS demographic_profile
    FROM 
        customer_demographics
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.full_address,
        d.demographic_profile
    FROM 
        customer c
    JOIN 
        AddressParts ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        cd.c_customer_sk,
        cd.full_name,
        cd.full_address,
        cd.demographic_profile,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit,
        COALESCE(ss.total_orders, 0) AS total_orders
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_net_profit > 1000 THEN 'High Value Customer'
        WHEN total_net_profit > 0 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    FinalReport
ORDER BY 
    total_net_profit DESC;
