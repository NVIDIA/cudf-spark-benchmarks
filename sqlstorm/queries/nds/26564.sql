WITH address_data AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        SUM(CASE WHEN ca_street_type IN ('St', 'Avenue', 'Blvd', 'Rd', 'Ln') THEN 1 ELSE 0 END) AS residential_streets,
        SUM(CASE WHEN ca_street_type IN ('Pkwy', 'Hwy', 'Bway') THEN 1 ELSE 0 END) AS major_highways
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demographic_data AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependency_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
sales_data AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    ad.ca_state,
    ad.total_addresses,
    ad.unique_cities,
    ad.residential_streets,
    ad.major_highways,
    dd.cd_gender,
    dd.total_customers,
    dd.avg_purchase_estimate,
    dd.avg_dependency_count,
    sd.d_year,
    sd.total_net_profit,
    sd.total_quantity_sold,
    sd.total_orders
FROM 
    address_data ad
JOIN 
    demographic_data dd ON 1=1  
JOIN 
    sales_data sd ON 1=1  
ORDER BY 
    ad.ca_state, dd.cd_gender, sd.d_year;