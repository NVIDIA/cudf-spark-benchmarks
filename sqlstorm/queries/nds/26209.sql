
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS total_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        COUNT(DISTINCT ca_city) AS unique_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer_demographics 
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT
        d_year,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.max_street_name_length,
    a.avg_street_name_length,
    a.unique_cities,
    c.cd_gender,
    c.total_customers,
    c.avg_dependents,
    c.max_purchase_estimate,
    s.d_year,
    s.total_sales,
    s.total_orders
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON c.total_customers > 100
JOIN 
    SalesStats s ON s.total_sales > 50000
ORDER BY 
    a.ca_state, c.cd_gender, s.d_year;
