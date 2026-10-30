
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_length,
        MAX(CASE WHEN ca_city IS NOT NULL THEN LENGTH(ca_city) ELSE 0 END) AS max_city_length,
        MIN(CASE WHEN ca_city IS NOT NULL THEN LENGTH(ca_city) ELSE LENGTH(ca_street_name) END) AS min_city_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
GenderStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_records,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
FinalStats AS (
    SELECT 
        a.ca_state,
        a.total_addresses,
        a.avg_street_length,
        a.max_city_length,
        a.min_city_length,
        g.cd_gender,
        g.total_records AS gender_record_count,
        g.avg_dependents AS avg_dependents,
        g.total_purchase_estimate,
        s.d_year,
        s.total_sales,
        s.total_orders
    FROM 
        AddressStats a
    LEFT JOIN 
        GenderStats g ON g.total_records > 0
    LEFT JOIN 
        SalesStats s ON s.total_sales > 0
)
SELECT 
    ca_state,
    total_addresses,
    avg_street_length,
    max_city_length,
    min_city_length,
    cd_gender,
    gender_record_count,
    avg_dependents,
    total_purchase_estimate,
    d_year,
    total_sales,
    total_orders
FROM 
    FinalStats
ORDER BY 
    ca_state, cd_gender, d_year;
