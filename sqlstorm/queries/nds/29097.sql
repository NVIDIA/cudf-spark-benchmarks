WITH AddressStats AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(DISTINCT ca_street_name) AS unique_street_names,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(LENGTH(ca_city)) AS total_city_length
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales_revenue,
        COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    A.ca_city,
    A.unique_addresses,
    A.unique_street_names,
    A.avg_street_name_length,
    A.total_city_length,
    D.cd_gender,
    D.total_customers,
    D.avg_purchase_estimate,
    D.total_dependents,
    S.ws_ship_date_sk,
    S.total_quantity_sold,
    S.total_sales_revenue,
    S.distinct_orders
FROM 
    AddressStats A
JOIN 
    DemographicStats D ON A.ca_city = 'San Francisco'  
JOIN 
    SalesStats S ON S.ws_ship_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales)  
ORDER BY 
    A.unique_addresses DESC, D.total_customers DESC;