
WITH AddressStats AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT CONCAT(ca_street_name, ' ', ca_street_number, ' ', ca_street_type), ', ') AS full_street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        'web' AS sales_channel,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        STRING_AGG(DISTINCT CAST(ws_web_page_sk AS STRING), ', ') AS web_page_ids
    FROM 
        web_sales
    GROUP BY 
        sales_channel
    UNION ALL
    SELECT 
        'store' AS sales_channel,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_sales_price) AS total_sales,
        STRING_AGG(DISTINCT CAST(ss_store_sk AS STRING), ', ') AS store_ids
    FROM 
        store_sales
    GROUP BY 
        sales_channel
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.full_street_names,
    d.cd_gender,
    d.demographic_count,
    d.marital_statuses,
    d.education_levels,
    s.sales_channel,
    s.total_quantity,
    s.total_sales,
    s.web_page_ids
FROM 
    AddressStats a
JOIN 
    DemographicStats d ON d.demographic_count > 100
JOIN 
    SalesStats s ON s.total_quantity > 1000
ORDER BY 
    a.ca_city, a.ca_state, d.cd_gender, s.sales_channel;
