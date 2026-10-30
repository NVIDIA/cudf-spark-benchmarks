
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        SUM(LENGTH(ca_street_name) + LENGTH(ca_street_type)) AS total_length,
        MAX(LENGTH(ca_city)) AS max_city_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsSummary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd_credit_rating) AS unique_credit_ratings
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesDetails AS (
    SELECT 
        ws_bill_cdemo_sk AS customer_demo_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_net_paid
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    ac.ca_state,
    ac.total_addresses,
    ac.total_length,
    ac.max_city_length,
    dc.cd_gender,
    dc.total_customers,
    dc.avg_purchase_estimate,
    dc.unique_credit_ratings,
    sd.total_net_profit,
    sd.total_orders,
    sd.avg_net_paid
FROM 
    AddressSummary ac
JOIN 
    DemographicsSummary dc ON dc.total_customers > 100
LEFT JOIN 
    SalesDetails sd ON dc.total_customers > 10
ORDER BY 
    ac.total_addresses DESC, 
    sd.total_net_profit DESC;
