WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        MIN(ca_city) AS min_city,
        MAX(ca_city) AS max_city,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        COUNT(DISTINCT ca_zip) AS distinct_zip_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(*) AS customer_count,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        sm.sm_ship_mode_id,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_order_number) AS unique_orders
    FROM 
        web_sales 
    JOIN 
        ship_mode sm ON ws_ship_mode_sk = sm.sm_ship_mode_sk 
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    a.ca_state,
    a.address_count,
    a.min_city,
    a.max_city,
    a.avg_street_name_length,
    a.distinct_zip_count,
    c.cd_gender,
    c.avg_purchase_estimate,
    c.customer_count,
    c.total_dependents,
    s.sm_ship_mode_id,
    s.total_sales,
    s.avg_net_profit,
    s.unique_orders
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.address_count > 500  
JOIN 
    SalesStats s ON s.total_sales > 10000      
ORDER BY 
    a.ca_state, 
    c.cd_gender, 
    s.sm_ship_mode_id;