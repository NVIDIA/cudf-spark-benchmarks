WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        SUM(CASE WHEN LENGTH(ca_street_name) > 0 THEN 1 ELSE 0 END) AS non_empty_street_names,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_marital_status,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependent_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_marital_status
),
SalesStats AS (
    SELECT 
        ws_ship_date_sk,
        COUNT(*) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_net_profit) AS avg_net_profit,
        MAX(ws_net_profit) AS max_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.non_empty_street_names,
    a.avg_street_name_length,
    a.max_street_name_length,
    c.cd_marital_status,
    c.total_customers,
    c.avg_dependent_count,
    c.max_purchase_estimate,
    c.min_purchase_estimate,
    s.ws_ship_date_sk,
    s.total_sales,
    s.total_net_profit,
    s.avg_net_profit,
    s.max_net_profit
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.total_addresses > 100 
JOIN 
    SalesStats s ON s.total_sales > 50 
ORDER BY 
    a.ca_state, 
    c.cd_marital_status, 
    s.ws_ship_date_sk;