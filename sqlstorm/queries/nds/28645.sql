
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_length,
        MIN(LENGTH(ca_street_name)) AS min_street_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        d_year,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.max_street_length,
    a.min_street_length,
    d.cd_gender,
    d.total_customers,
    d.avg_dependents,
    d.total_purchase_estimate,
    s.d_year,
    s.total_sales,
    s.avg_profit
FROM 
    AddressStats a
JOIN 
    DemographicStats d ON d.total_customers > 50
JOIN 
    SalesStats s ON s.total_sales > 1000000
ORDER BY 
    a.ca_state, d.cd_gender, s.d_year DESC;
