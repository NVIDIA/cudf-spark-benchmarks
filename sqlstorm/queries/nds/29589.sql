
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MIN(ca_zip) AS min_zip,
        MAX(ca_zip) AS max_zip
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_demographics,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.avg_street_name_length,
    a.min_zip,
    a.max_zip,
    d.cd_gender,
    d.total_demographics,
    d.avg_purchase_estimate,
    d.highest_credit_rating,
    s.total_net_profit,
    s.total_orders,
    s.avg_sales_price
FROM 
    AddressStats a
JOIN 
    DemographicsStats d ON a.total_addresses > 100
CROSS JOIN 
    SalesStats s
WHERE 
    a.total_addresses > 200
ORDER BY 
    a.ca_state, d.cd_gender;
