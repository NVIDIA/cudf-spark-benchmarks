
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    WHERE 
        ca_city LIKE '%town%'
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS unique_demographics,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
RecentActivities AS (
    SELECT 
        d_year, 
        COUNT(ws_order_number) AS total_web_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        d_year >= 2023
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.total_addresses,
    a.avg_street_name_length,
    d.cd_gender,
    d.unique_demographics,
    d.avg_purchase_estimate,
    d.total_dependents,
    r.d_year,
    r.total_web_sales,
    r.total_net_profit
FROM 
    AddressStats a
JOIN 
    DemographicStats d ON d.unique_demographics > 10
JOIN 
    RecentActivities r ON r.total_web_sales > 1000
ORDER BY 
    a.ca_state, d.cd_gender, r.d_year DESC;
