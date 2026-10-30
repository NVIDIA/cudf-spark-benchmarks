
WITH AddressParts AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state, ca_street_number, ca_street_name, ca_street_type
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        ds.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws 
    JOIN 
        date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    GROUP BY 
        ds.d_year
),
FinalAnalytics AS (
    SELECT 
        ap.ca_city,
        ap.ca_state,
        ap.full_address,
        ap.address_count,
        ds.cd_gender,
        ds.demographic_count,
        ds.avg_purchase_estimate,
        ss.d_year,
        ss.total_profit,
        ss.total_orders
    FROM 
        AddressParts ap
    CROSS JOIN 
        DemographicStats ds
    CROSS JOIN 
        SalesStats ss
)
SELECT 
    ca.ca_city AS city, 
    ca.ca_state AS state, 
    ca.full_address, 
    ca.address_count,
    dem.cd_gender, 
    dem.demographic_count, 
    dem.avg_purchase_estimate,
    sales.d_year,
    sales.total_profit,
    sales.total_orders
FROM 
    FinalAnalytics ca
JOIN 
    DemographicStats dem ON dem.cd_gender = 'M'  
JOIN 
    SalesStats sales ON sales.d_year = 2001  
ORDER BY 
    ca.ca_city, ca.ca_state, dem.cd_gender;
