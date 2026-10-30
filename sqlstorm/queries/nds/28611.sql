WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        COUNT(DISTINCT ca_city) AS distinct_city_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesStats AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.address_count,
    a.distinct_city_count,
    a.avg_street_name_length,
    d.cd_gender,
    d.cd_marital_status,
    d.avg_purchase_estimate,
    d.total_dependents,
    s.d_year,
    s.total_net_profit,
    s.total_orders,
    s.total_quantity_sold
FROM 
    AddressStats a
JOIN 
    DemographicStats d ON a.ca_state = 'CA' 
JOIN 
    SalesStats s ON s.d_year = 2001 
ORDER BY 
    a.address_count DESC, 
    d.avg_purchase_estimate DESC;